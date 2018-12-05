# frozen_string_literal: true

require "forwardable"
require "cuprite/browser/client"

# RemoteObjectId is from a JavaScript world, and corresponds to any JavaScript
# object, including JS wrappers for DOM nodes. There is a way to convert between
# node ids and remote object ids (DOM.requestNode and DOM.resolveNode).
#
# NodeId is used for inspection, when backend tracks the node and sends updates to
# the frontend. If you somehow got NodeId over protocol, backend should have
# pushed to the frontend all of it's ancestors up to the Document node via
# DOM.setChildNodes. After that, frontend is always kept up-to-date about anything
# happening to the node.
#
# BackendNodeId is just a unique identifier for a node. Obtaining it does not send
# any updates, for example, the node may be destroyed without any notification.
# This is a way to keep a reference to the Node, when you don't necessarily want
# to keep track of it. One example would be linking to the node from performance
# data (e.g. relayout root node). BackendNodeId may be either resolved to
# inspected node (DOM.pushNodesByBackendIdsToFrontend) or described in more
# details (DOM.describeNode).
module Capybara::Cuprite
  class Browser
    class Page
      extend Forwardable

      delegate [:wait, :subscribe] => :@client
      delegate targets: :@browser

      attr_reader :target_id, :status_code

      def initialize(target_id, browser, logger)
        @target_id = target_id
        @browser, @logger = browser, logger
        @query_root_node = false
        @execution_context_mutex = Mutex.new

        begin
          @session_id = @browser.command("Target.attachToTarget", targetId: @target_id)["sessionId"]
        rescue BrowserError => e
          if e.message == "No target with given id found"
            raise NoSuchWindowError
          else
            raise
          end
        end

        host = @browser.process.host
        port = @browser.process.port
        ws_url = "ws://#{host}:#{port}/devtools/page/#{@target_id}"
        @client = Client.new(ws_url, @logger)

        subscribe_events
        prepare_page
      end

      def visit(url)
        frame_id = command("Page.navigate", url: url)["frameId"]
        wait("Page.frameStoppedLoading", frameId: frame_id)
        true
      end

      def close
        @browser.command("Target.detachFromTarget", sessionId: @session_id)
        @browser.command("Target.closeTarget", targetId: @target_id)
        close_connection
      end

      def close_connection
        @client.close
      end

      def resize(width, height)
        result = @browser.command("Browser.getWindowForTarget", targetId: @target_id)
        @window_id, @bounds = result.values_at("windowId", "bounds")
        @browser.command("Browser.setWindowBounds", windowId: @window_id, bounds: { width: width, height: height })
        command("Emulation.setDeviceMetricsOverride", width: width, height: height, deviceScaleFactor: 1, mobile: false)
      end

      def evaluate(node, expr)
        resolved = command("DOM.resolveNode", nodeId: node["nodeId"])
        object_id = resolved.dig("object", "objectId")
        command("Runtime.callFunctionOn", objectId: object_id, functionDeclaration: %Q(
          function () { return #{expr} }
        )).dig("result", "value")
      end

      def execution_context_id
        @execution_context_mutex.synchronize { @execution_context_id }
      end

      def command(*args)
        if @query_root_node
          begin
            get_document
          ensure
            @query_root_node = false
          end
        end

        @client.command(*args)
      end

      private

      def read(filename)
        File.read(File.expand_path("javascripts/#{filename}", __dir__))
      end

      def subscribe_events
        subscribe("Runtime.consoleAPICalled") do |params|
          params["args"].each { |r| @logger.write(r["value"]) }
        end
        subscribe("Runtime.executionContextCreated") do |params|
          @execution_context_id ||= params.dig("context", "id")
          @execution_context_mutex.unlock if @execution_context_mutex.locked?
        end
        subscribe("Runtime.executionContextDestroyed") do |params|
          if @execution_context_id == params["executionContextId"]
            @execution_context_mutex.lock
            @execution_context_id = nil
          end
        end
        subscribe("Runtime.executionContextsCleared") do
          # If we didn't have time to set context id at the beginning we have
          # to set lock and release it when we set something.
          @execution_context_id = nil
          @execution_context_mutex.lock
        end
        subscribe("Page.windowOpen") { targets.refresh }
        subscribe("Page.frameStartedLoading") do |params|
          # Remember the first frame started loading since it's the main one
          @frame_id ||= params["frameId"]
        end
        subscribe("Page.frameStoppedLoading") do |params|
          # `DOM.performSearch` doesn't work without getting #document node first.
          # It returns node with nodeId 1 and nodeType 9 from which descend the
          # tree and we save it in a variable because if we call that again root
          # node will change the id and all subsequent nodes have to change id too.
          # `command` is not allowed in the block as it will deadlock the process.
          @query_root_node = true if params["frameId"] == @frame_id
        end
        subscribe("Network.requestWillBeSent") do |params|
          @request_id = params["requestId"] if params["type"] == "Document"
        end
        subscribe("Network.responseReceived") do |params|
          if params["requestId"] == @request_id
            @status_code = params.dig("response", "status")
          end
        end
        subscribe("Page.domContentEventFired") do |params|
          # `Page.frameStoppedLoading` doesn't occur if status isn't success
          @query_root_node = true if @status_code != 200
        end
      end

      def prepare_page
        command("Page.enable")
        command("DOM.enable")
        command("CSS.enable")
        command("Runtime.enable")
        command("Log.enable")
        command("Network.enable")
        command("Page.addScriptToEvaluateOnNewDocument", source: read("index.js"))

        response = command("Page.getNavigationHistory")
        if response.dig("entries", 0, "transitionType") != "typed"
          # If we create page by clicking links, submiting forms and so on it
          # opens a new window for which `Page.frameStoppedLoading` event never
          # occurs and thus search for nodes cannot be completed. Here we check
          # the history and if the event for example `link` then content is
          # already loaded and we can try to get the document. It is not only
          # true for this event in particular, see other issues:
          # https://github.com/GoogleChrome/puppeteer/issues/1443
          # https://github.com/ChromeDevTools/devtools-protocol/issues/77
          # https://github.com/cyrus-and/chrome-remote-interface/issues/319
          # We also evaluate script manually because `Page.addScriptToEvaluateOnNewDocument`
          # doesn't work in popup windows.

          command("Runtime.evaluate", expression: read("index.js"),
                                      contextId: @execution_context_id,
                                      returnByValue: true)
          get_document
        end
      end

      def get_document
        @client.command("DOM.getDocument", depth: 0)["root"]
      end
    end
  end
end

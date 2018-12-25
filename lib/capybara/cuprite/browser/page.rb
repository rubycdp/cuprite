# frozen_string_literal: true

require "cuprite/browser/dom"
require "cuprite/browser/input"
require "cuprite/browser/client"
require "cuprite/network/error"
require "cuprite/network/request"
require "cuprite/network/response"

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
      include Input, DOM

      attr_accessor :referrer
      attr_reader :target_id, :status_code, :response_headers

      def initialize(target_id, browser)
        @wait = 0
        @target_id, @browser = target_id, browser
        @mutex, @resource = Mutex.new, ConditionVariable.new
        @network_traffic = []

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
        @client = Client.new(browser, ws_url)

        subscribe_events
        prepare_page
      end

      def execution_context_id
        @mutex.synchronize { @execution_context_id }
      end

      def timeout
        @browser.timeout
      end

      def visit(url)
        @wait = timeout
        options = { url: url }
        options.merge!(referrer: referrer) if referrer
        response = command("Page.navigate", **options)
        if response["errorText"] == "net::ERR_NAME_RESOLUTION_FAILED"
          raise StatusFailError, "url" => url
        end
        response["frameId"]
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

      def refresh
        @wait = timeout
        command("Page.reload")
      end

      def network_traffic(type = nil)
        case type
        when "all"
          @network_traffic
        when "blocked"
          @network_traffic # when request blocked
        else
          @network_traffic # when not request blocked
        end
      end

      def clear_network_traffic
        @network_traffic = []
      end

      def command(*args)
        id = nil

        @mutex.synchronize do
          id = @client.command(*args)
          stop_at = Time.now.to_f + @wait

          while @wait > 0 && (remain = stop_at - Time.now.to_f) > 0
            @resource.wait(@mutex, remain)
          end

          @wait = 0
        end

        response = @client.wait(id: id)
      end

      private

      def subscribe_events
        @client.subscribe("Runtime.consoleAPICalled") do |params|
          if @browser.logger
            params["args"].each { |r| @browser.logger.write(r["value"]) }
          end
        end

        @client.subscribe("Runtime.executionContextCreated") do |params|
          # Remember the very first frame since it's the main one
          @frame_id ||= params.dig("context", "auxData", "frameId")
          @execution_context_id ||= params.dig("context", "id")
        end

        @client.subscribe("Runtime.executionContextDestroyed") do |params|
          if @execution_context_id == params["executionContextId"]
            @execution_context_id = nil
          end
        end

        @client.subscribe("Runtime.executionContextsCleared") do
          # If we didn't have time to set context id at the beginning we have
          # to set lock and release it when we set something.
          @execution_context_id = nil
        end

        @client.subscribe("Page.windowOpen") do
          @browser.targets.refresh
          sleep 0.3 # Dirty hack because new window doesn't have events at all
        end

        @client.subscribe("Page.frameStoppedLoading") do |params|
          # `DOM.performSearch` doesn't work without getting #document node first.
          # It returns node with nodeId 1 and nodeType 9 from which descend the
          # tree and we save it in a variable because if we call that again root
          # node will change the id and all subsequent nodes have to change id too.
          # `command` is not allowed in the block as it will deadlock the process.
          if params["frameId"] == @frame_id
            @wait = 0

            if @mutex.locked? && @mutex.owned?
              @resource.signal
              @mutex.unlock
            else
              @mutex.synchronize { @resource.signal }
            end

            @client.command("DOM.getDocument", depth: 0)
          end
        end

        @client.subscribe("Page.frameScheduledNavigation") do |params|
          @mutex.try_lock if params["frameId"] == @frame_id
        end

        @client.subscribe("Network.requestWillBeSent") do |params|
          if params["frameId"] == @frame_id
            # Possible types:
            # Document, Stylesheet, Image, Media, Font, Script, TextTrack, XHR,
            # Fetch, EventSource, WebSocket, Manifest, SignedExchange, Ping,
            # CSPViolationReport, Other
            if params["type"] == "Document"
              @mutex.try_lock
              @request_id = params["requestId"]
            end
          end

          id, time = params.values_at("requestId", "wallTime")
          params = params["request"].merge("id" => id, "time" => time)
          @network_traffic << Network::Request.new(params)
        end

        @client.subscribe("Network.responseReceived") do |params|
          if params["requestId"] == @request_id
            @response_headers = params.dig("response", "headers")
            @status_code = params.dig("response", "status")
          end

          if request = @network_traffic.find { |r| r.id == params["requestId"] }
            params = params["response"].merge("id" => params["requestId"])
            request.response = Network::Response.new(params)
          end
        end

        @client.subscribe("Page.navigatedWithinDocument") do
          @wait = 0

          if @mutex.locked? && @mutex.owned?
            @resource.signal
            @mutex.unlock
          else
            @mutex.synchronize { @resource.signal }
          end
        end

        @client.subscribe("Log.entryAdded") do |params|
          source = params.dig("entry", "source")
          level = params.dig("entry", "level")
          if source == "network" && level == "error"
            id = params.dig("entry", "networkRequestId")
            if request = @network_traffic.find { |r| r.id == id }
              request.error = Network::Error.new(params["entry"])
            end
          end
        end

        @client.subscribe("Page.domContentEventFired") do |params|
          # `Page.frameStoppedLoading` doesn't occur if status isn't success
          if @status_code != 200
            @wait = 0

            if @mutex.locked? && @mutex.owned?
              @resource.signal
              @mutex.unlock
            else
              @mutex.synchronize { @resource.signal }
            end

            @client.command("DOM.getDocument", depth: 0)
          end
        end

        @client.subscribe("Network.requestIntercepted") do |params|
          @client.command("Network.continueInterceptedRequest", interceptionId: params["interceptionId"], errorReason: "Aborted")
        end
      end

      def prepare_page
        command("Page.enable")
        command("DOM.enable")
        command("CSS.enable")
        command("Runtime.enable")
        command("Log.enable")
        command("Network.enable")

        @browser.extensions.each do |extension|
          command("Page.addScriptToEvaluateOnNewDocument", source: extension)

          # https://github.com/GoogleChrome/puppeteer/issues/1443
          # https://github.com/ChromeDevTools/devtools-protocol/issues/77
          # https://github.com/cyrus-and/chrome-remote-interface/issues/319
          # We also evaluate script just in case because
          # `Page.addScriptToEvaluateOnNewDocument` doesn't work in popups.
          command("Runtime.evaluate", expression: extension,
                                      contextId: @execution_context_id,
                                      returnByValue: true)
        end

        response = command("Page.getNavigationHistory")
        if response.dig("entries", 0, "transitionType") != "typed"
          # If we create page by clicking links, submiting forms and so on it
          # opens a new window for which `Page.frameStoppedLoading` event never
          # occurs and thus search for nodes cannot be completed. Here we check
          # the history and if the transitionType for example `link` then
          # content is already loaded and we can try to get the document.
          @client.command("DOM.getDocument", depth: 0)
        end
      end
    end
  end
end

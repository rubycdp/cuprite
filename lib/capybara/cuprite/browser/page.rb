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

      delegate [:command, :wait, :subscribe] => :@client

      def initialize(browser, logger)
        @browser, @logger = browser, logger
        @context_id = @browser.command("Target.createBrowserContext")["browserContextId"]
        @target_id  = @browser.command("Target.createTarget", url: "about:blank", browserContextId: @context_id)["targetId"]
        @session_id = @browser.command("Target.attachToTarget", targetId: @target_id)["sessionId"]

        host = @browser.process.host
        port = @browser.process.port
        ws_url = "ws://#{host}:#{port}/devtools/page/#{@target_id}"
        @client = Client.new(ws_url, @logger)

        command("Page.enable")
        command("DOM.enable")
        command("CSS.enable")
        command("Runtime.enable")

        command("Page.addScriptToEvaluateOnNewDocument", source: read("index.js"))

        subscribe "Page.frameStoppedLoading" do
          # `DOM.performSearch` doesn't work without getting #document node first.
          # It returns node with nodeId 1 and nodeType 9 from which descend the
          # tree and we save it in a variable because if we call that again root
          # node will change the id and all subsequent nodes have to change id too.
          command("DOM.getDocument", depth: 0)["root"]
        end
      end

      def visit(url)
        response = command("Page.navigate", url: url)
        wait("Page.frameStoppedLoading", frameId: response["frameId"])
        true
      end

      def close
        @browser.command("Target.detachFromTarget", sessionId: @session_id)
        @browser.command("Target.closeTarget", targetId: @target_id)
        @browser.command("Target.disposeBrowserContext", browserContextId: @context_id)
        @client.close
      end

      def resize(width, height)
        result = @browser.command("Browser.getWindowForTarget", targetId: @target_id)
        @window_id, @bounds = result.values_at("windowId", "bounds")
        @browser.command("Browser.setWindowBounds", windowId: @window_id, bounds: { width: width, height: height })
        command("Emulation.setDeviceMetricsOverride", width: width, height: height, deviceScaleFactor: 1, mobile: false)
      end

      private

      def read(filename)
        File.read(File.expand_path("javascripts/#{filename}", __dir__))
      end
    end
  end
end

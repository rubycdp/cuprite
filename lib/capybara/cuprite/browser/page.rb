# frozen_string_literal: true

require "forwardable"
require "cuprite/browser/client"

module Capybara::Cuprite
  class Browser
    class Page
      extend Forwardable

      delegate [:command, :wait] => :@client

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
      end

      def visit(url)
        response = command("Page.navigate", url: url)
        wait(event: "Page.frameStoppedLoading") do |params|
          params["frameId"] == response["frameId"]
        end

        # `DOM.performSearch` doesn't work without getting #document node first.
        # It returns node with nodeId 1 and nodeType 9 from which descend the
        # tree and we save it in a variable because if we call that again root
        # node will change the id and all subsequent nodes have to change id too.
        @root = command("DOM.getDocument", depth: 0)["root"]

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
    end
  end
end

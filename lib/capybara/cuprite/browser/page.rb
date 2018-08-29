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
      end

      def close
        @browser.command("Target.detachFromTarget", sessionId: @session_id)
        @browser.command("Target.closeTarget", targetId: @target_id)
        @browser.command("Target.disposeBrowserContext", browserContextId: @context_id)
        @client.close
      end
    end
  end
end

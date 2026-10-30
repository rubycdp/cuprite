# frozen_string_literal: true

require "capybara/cuprite/page/frames"
require "capybara/cuprite/page/modals"

module Capybara
  module Cuprite
    class Page < Ferrum::Page
      EXTENSION_JS = File.read(Driver::EXTENSION).freeze

      include Frames
      include Modals

      def set_viewport(width: 0, height: 0, scale_factor: @options.scale_factor, mobile: @options.mobile)
        super
      end

      private

      def subscribe
        super
        return unless @options.raise_on_js_errors

        on("Runtime.exceptionThrown") do |params|
          Thread.main.raise Ferrum::JavaScriptError, params["exceptionDetails"]
        end
      end

      def prepare_page
        super
        execute(EXTENSION_JS)

        width, height = @options.window_size
        width && height ? resize(width: width, height: height) : set_viewport
        command("Network.setUserAgentOverride", userAgent: default_user_agent) if @options.device_user_agent

        if @options.url_blacklist.any?
          network.blacklist = @options.url_blacklist
        elsif @options.url_whitelist.any?
          network.whitelist = @options.url_whitelist
        end
      end
    end
  end
end

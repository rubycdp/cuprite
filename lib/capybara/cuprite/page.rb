# frozen_string_literal: true

require "capybara/cuprite/page/frames"
require "capybara/cuprite/page/modals"

module Capybara
  module Cuprite
    class Page < Ferrum::Page
      EXTENSION_JS = File.read(Driver::EXTENSION).freeze

      include Frames
      include Modals

      # Navigates the page to a URL, see `Ferrum::Page#go_to`.
      #
      # @param url [String, nil]
      # @param options [Hash] the keywords of `Ferrum::Page#go_to`, like `referrer:` and `timeout:`
      # @return [String, nil] the navigated frame's id
      # @raise [PendingConnectionsError] with `pending_connection_errors` when the page doesn't load in time
      def go_to(url = nil, **options)
        frame_id = super
        return frame_id if frame_id || !@options.raise_on_pending_connections

        pendings = network.traffic.select(&:pending?).map(&:url).compact
        raise PendingConnectionsError.new(combine_url!(url), pendings)
      end

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
        network.emulate(user_agent: default_user_agent) if @options.device_user_agent

        if @options.url_blacklist.any?
          network.blacklist = @options.url_blacklist
        elsif @options.url_whitelist.any?
          network.whitelist = @options.url_whitelist
        end
      end
    end
  end
end

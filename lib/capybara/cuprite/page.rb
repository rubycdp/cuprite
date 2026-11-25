# frozen_string_literal: true

require "capybara/cuprite/page/frames"
require "capybara/cuprite/page/modals"

module Capybara
  module Cuprite
    # A Ferrum page with Cuprite's JavaScript, frame switching and dialog handling.
    # @api private
    class Page < Ferrum::Page
      # The JavaScript Cuprite adds to every page.
      EXTENSION_JS = File.read(Driver::EXTENSION).freeze

      include Frames
      include Modals

      # @param client [Ferrum::Client, Ferrum::SessionClient]
      # @param settings [Browser::Settings] the options only Cuprite handles
      # @param options [Hash] the keywords of `Ferrum::Page#initialize`
      def initialize(client, settings:, **options)
        @settings = settings
        super(client, **options)
      end

      # Navigates the page to a URL, see `Ferrum::Page#go_to`.
      #
      # @param url [String, nil]
      # @param options [Hash] the keywords of `Ferrum::Page#go_to`, like `referrer:` and `timeout:`
      # @return [String, nil] the navigated frame's id
      # @raise [PendingConnectionsError] with `pending_connection_errors` when the page doesn't load in time
      def go_to(url = nil, **options)
        frame_id = super
        return frame_id if frame_id || !@settings.pending_connection_errors?

        pendings = network.traffic.select(&:pending?).map(&:url).compact
        raise PendingConnectionsError.new(combine_url!(url), pendings)
      end

      # Sets the viewport, keeping the `scale_factor:` and `mobile:` options unless given.
      #
      # @return [void]
      def set_viewport(width: 0, height: 0, scale_factor: @settings.scale_factor, mobile: @settings.mobile)
        super
      end

      # Ferrum's network falls back to it when it clears other overrides, so the device's user agent stays.
      #
      # @return [String, nil] the emulated device's user agent, or Chrome's own
      def default_user_agent
        @settings.user_agent(super)
      end

      private

      def subscribe
        super
        return unless @settings.js_errors?

        on("Runtime.exceptionThrown") do |params|
          Thread.main.raise Ferrum::JavaScriptError, params["exceptionDetails"]
        end
      end

      def prepare_page
        super
        execute(EXTENSION_JS)

        width, height = @settings.window_size
        width && height ? resize(width: width, height: height) : set_viewport
        network.emulate(user_agent: default_user_agent) if @settings.device_user_agent?

        network.blacklist = @settings.url_blacklist if @settings.url_blacklist.any?
        network.whitelist = @settings.url_whitelist if @settings.url_whitelist.any?
      end
    end
  end
end

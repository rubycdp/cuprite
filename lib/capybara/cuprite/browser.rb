# frozen_string_literal: true

require "capybara/cuprite/browser/extensions"
require "capybara/cuprite/browser/settings"
require "capybara/cuprite/page_state"

module Capybara
  module Cuprite
    # The Ferrum browser behind {Driver#browser}. Its public API is Ferrum's plus {Browser::Extensions}; the methods
    # here only adapt Ferrum to Capybara.
    class Browser < Ferrum::Browser
      include Extensions

      # The JavaScript Cuprite adds to every page.
      EXTENSION_JS = File.read(Driver::EXTENSION).freeze

      delegate %i[at_css at_xpath css xpath html evaluate execute] => :active_frame

      # @api private
      # @param options [Hash, nil] the {Driver} options
      def initialize(options = nil)
        device = options&.dig(:emulate)
        options = Devices.fetch(device).except(:user_agent).merge(options) if device
        super(options&.except(:js_errors, :pending_connection_errors))

        @settings = Settings.new(options, self.options.window_size)
        @page = nil
        @page_states = {}
        on_page { |page| prepare_page(page) }
      end

      # Restarts a browser that died before raising the error.
      # @api private
      def command(...)
        super
      rescue Ferrum::DeadBrowserError
        restart
        raise
      end

      # @api private
      # @return [Ferrum::Page] the current page
      # @raise [Ferrum::NoSuchPageError] when the current window was closed
      def page
        raise Ferrum::NoSuchPageError if @page_closed

        @page ||= super
      end

      # @api private
      # @param page [Ferrum::Page]
      # @return [PageState] what Cuprite keeps for the page, the current one by default
      def page_state(page = self.page)
        @page_states.fetch(page.target_id)
      end

      # Navigates the current page, see `Ferrum::Page#go_to`.
      #
      # @api private
      # @param url [String, nil]
      # @param options [Hash] the keywords of `Ferrum::Page#go_to`, like `referrer:` and `timeout:`
      # @return [String, nil] the navigated frame's id
      # @raise [PendingConnectionsError] with `pending_connection_errors` when the page doesn't load in time
      def go_to(url = nil, **options)
        return super unless @settings.pending_connection_errors?

        begin
          go_to!(url, **options)
        rescue Ferrum::NavigationTimeoutError => e
          raise if Ferrum::Deadline.current&.expired?

          raise PendingConnectionsError.new(e.url, e.pendings)
        end
      end

      # Sets the viewport, keeping the `scale_factor:` and `mobile:` options unless given.
      #
      # @api private
      # @return [nil]
      def set_viewport(width: 0, height: 0, scale_factor: @settings.scale_factor, mobile: @settings.mobile)
        super
      end

      # @api private
      # @return [void]
      def reset
        @page_states.clear
        super
      ensure
        @settings.reset
        forget_page
      end

      # @api private
      # @return [void]
      def quit
        @page_states.clear
        super
        forget_page
      end

      # Keeps the size for the windows opened next, and the `scale_factor:` and `mobile:` options.
      # @api private
      # @return [nil]
      def resize(**options)
        @settings.window_size = [options[:width], options[:height]]
        super
        width, height = options[:fullscreen] ? document_size : options.values_at(:width, :height)
        set_viewport(width: width, height: height)
      end

      # @api private
      # @return [String]
      def current_window_handle
        page.target_id
      end

      # @api private
      # @return [Array<String>]
      def window_handles
        targets.values.select(&:page?).map(&:id)
      end

      # Opens a blank page without switching to it.
      #
      # @api private
      # @param kind [:tab, :window] a tab in the current window, or a window of its own
      # @return [Ferrum::Page]
      # @raise [ArgumentError] for any other kind
      def open_new_window(kind = :tab)
        unless %i[tab window].include?(kind)
          raise ArgumentError, "open_new_window takes :tab or :window, got #{kind.inspect}"
        end

        default_context.create_page(new_window: kind == :window)
      end

      # @api private
      # @param target_id [String]
      # @return [void]
      # @raise [Ferrum::NoSuchPageError]
      def switch_to_window(target_id)
        target = window_target(target_id)
        forget_page
        @page = target.page
        @page.activate
      end

      # @api private
      # @param target_id [String]
      # @return [void]
      # @raise [Ferrum::NoSuchPageError]
      def close_window(target_id)
        target = window_target(target_id)
        if @page&.target_id == target.id
          forget_page
          @page_closed = true
        end
        default_context.close_target(target.id).tap { @page_states.delete(target.id) }
      end

      private

      def forget_page
        @page = nil
        @page_closed = false
      end

      def window_target(target_id)
        target = targets[target_id]
        raise Ferrum::NoSuchPageError unless target&.page?

        target
      end

      def prepare_page(page)
        @page_states[page.target_id] = PageState.new(page, @settings)
        subscribe_to_js_errors(page) if @settings.js_errors?
        page.execute(EXTENSION_JS)

        width, height = @settings.window_size
        page.resize(width: width, height: height) if width && height
        page.set_viewport(width: width || 0, height: height || 0, scale_factor: @settings.scale_factor,
                          mobile: @settings.mobile)
        emulate_device_user_agent(page) if @settings.device_user_agent?

        page.network.blacklist = @settings.url_blacklist if @settings.url_blacklist.any?
        page.network.whitelist = @settings.url_whitelist if @settings.url_whitelist.any?
      end

      def subscribe_to_js_errors(page)
        page.on("Runtime.exceptionThrown") do |params|
          Thread.main.raise Ferrum::JavaScriptError, params["exceptionDetails"]
        end
      end

      def emulate_device_user_agent(page)
        self.default_user_agent = @settings.user_agent(version.user_agent)
        page.network.emulate(user_agent: default_user_agent)
      end

      def active_frame
        page_state.active_frame
      end
    end
  end
end

# frozen_string_literal: true

require "capybara/cuprite/browser/extensions"
require "capybara/cuprite/browser/settings"

module Capybara
  module Cuprite
    # The Ferrum browser behind {Driver#browser}. Its public API is Ferrum's plus {Browser::Extensions}; the methods
    # here only adapt Ferrum to Capybara.
    class Browser < Ferrum::Browser
      include Extensions

      # @api private
      # @param options [Hash, nil] the {Driver} options
      def initialize(options = nil)
        device = options&.dig(:emulate)
        options = Devices.fetch(device).except(:user_agent).merge(options) if device
        super(options&.except(:js_errors, :pending_connection_errors))

        @settings = Settings.new(options, @options.window_size)
        @page = nil
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
      # @return [Page] the current page
      # @raise [Ferrum::NoSuchPageError] when the current window was closed
      def page
        raise Ferrum::NoSuchPageError if @page_closed

        @page ||= attach_page
      end

      # @api private
      # @return [void]
      def reset
        super
      ensure
        @settings.reset_window_size
        forget_page
      end

      # @api private
      # @return [void]
      def quit
        super
        forget_page
      end

      # Keeps the size for the windows opened next.
      # @api private
      # @return [void]
      def resize(**options)
        @settings.window_size = [options[:width], options[:height]]
        super
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
      # @return [Page]
      # @raise [ArgumentError] for any other kind
      def open_new_window(kind = :tab)
        unless %i[tab window].include?(kind)
          raise ArgumentError, "open_new_window takes :tab or :window, got #{kind.inspect}"
        end

        attach_page(default_context.create_target(new_window: kind == :window).id)
      end

      # @api private
      # @param target_id [String]
      # @return [void]
      # @raise [Ferrum::NoSuchPageError]
      def switch_to_window(target_id)
        target = window_target(target_id)
        forget_page
        @page = attach_page(target.id)
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
        target.page.close
        default_context.delete_target(target_id) # page.close is async, delete target asap
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

      def attach_page(target_id = nil)
        target = targets[target_id] if target_id
        target ||= default_context.default_target
        return target.page if target.connected?

        target.maybe_sleep_if_new_window
        target.page = Page.new(target.client, context_id: target.context_id, target_id: target.id, settings: @settings)
        target.page
      end
    end
  end
end

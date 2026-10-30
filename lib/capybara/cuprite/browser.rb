# frozen_string_literal: true

require "capybara/cuprite/browser/extensions"

module Capybara
  module Cuprite
    class Browser < Ferrum::Browser
      include Extensions

      def initialize(options = nil)
        device = options&.dig(:emulate)
        options = Devices.fetch(device).except(:user_agent).merge(options) if device
        super

        @options.raise_on_unhandled_modal = options&.dig(:raise_on_unhandled_modal)
        @options.url_blacklist = prepare_wildcards(options&.dig(:url_blacklist))
        @options.url_whitelist = prepare_wildcards(options&.dig(:url_whitelist))

        @page = nil
      end

      def command(...)
        super
      rescue Ferrum::DeadBrowserError
        restart
        raise
      end

      def page
        raise Ferrum::NoSuchPageError if @page_closed

        @page ||= attach_page
      end

      def reset
        super
      ensure
        @options.reset_window_size
        forget_page
      end

      def quit
        super
        forget_page
      end

      def resize(**options)
        @options.window_size = [options[:width], options[:height]]
        super
      end

      def current_window_handle
        page.target_id
      end

      def window_handles
        targets.values.select(&:page?).map(&:id)
      end

      def open_new_window
        attach_page(default_context.create_target.id)
      end

      def switch_to_window(target_id)
        target = window_target(target_id)
        forget_page
        @page = attach_page(target.id)
        @page.activate
      end

      def close_window(target_id)
        target = window_target(target_id)
        if @page&.target_id == target.id
          forget_page
          @page_closed = true
        end
        target.page.close
        targets.delete(target_id) # page.close is async, delete target asap
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
        target.page = Page.new(target.client, context_id: target.context_id, target_id: target.id)
        target.page
      end
    end
  end
end

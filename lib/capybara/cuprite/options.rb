# frozen_string_literal: true

module Ferrum
  class Browser
    # Cuprite's additions to Ferrum's browser options.
    # @api private
    class Options
      attr_writer :window_size
      attr_accessor :url_blacklist, :url_whitelist, :raise_on_unhandled_modal, :raise_on_js_errors,
                    :raise_on_pending_connections

      # @return [Boolean, nil]
      def mobile
        @options.fetch(:mobile, nil)
      end

      # @return [Numeric]
      def scale_factor
        @options.fetch(:scale_factor, 0)
      end

      # @return [String, nil] the user agent template of the emulated device
      def device_user_agent
        Capybara::Cuprite::Devices.fetch(@options[:emulate])[:user_agent] if @options[:emulate]
      end

      # @return [String] the emulated device's user agent with the Chrome version, or Chrome's own
      def default_user_agent
        return @default_user_agent unless device_user_agent

        chrome_version = @default_user_agent.to_s[%r{Chrome/(\S+)}, 1].to_s
        format(device_user_agent, version: chrome_version)
      end

      # Restores the `window_size:` option.
      # @return [void]
      def reset_window_size
        @window_size = @options[:window_size]
      end
    end
  end
end

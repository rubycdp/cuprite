# frozen_string_literal: true

module Ferrum
  class Browser
    class Options
      attr_writer :window_size
      attr_accessor :url_blacklist, :url_whitelist, :raise_on_unhandled_modal, :reset_mode

      def mobile
        @options.fetch(:mobile, false)
      end

      def scale_factor
        @options.fetch(:scale_factor, 0)
      end

      def device_user_agent
        Capybara::Cuprite::Devices.fetch(@options[:emulate])[:user_agent] if @options[:emulate]
      end

      def default_user_agent
        return @default_user_agent unless device_user_agent

        chrome_version = @default_user_agent.to_s[%r{Chrome/(\S+)}, 1].to_s
        format(device_user_agent, version: chrome_version)
      end

      def reset_window_size
        @window_size = @options[:window_size]
      end
    end
  end
end

# frozen_string_literal: true

module Capybara
  module Cuprite
    class Browser < Ferrum::Browser
      # The driver options only Cuprite handles, which {Browser} sets every page up with.
      # @api private
      class Settings
        # @return [Boolean, nil] whether an unhandled dialog raises {UnhandledModalError} instead of warning
        attr_accessor :raise_on_unhandled_modal
        # @return [Array(Integer, Integer), Array(nil, nil), nil] the size the windows opened next get
        attr_accessor :window_size
        # @return [Array<Regexp>]
        attr_reader :url_blacklist
        # @return [Array<Regexp>]
        attr_reader :url_whitelist
        # @return [Boolean, nil]
        attr_reader :mobile
        # @return [Numeric]
        attr_reader :scale_factor

        # @param options [Hash, nil] the {Driver} options, with those of the `emulate:` device merged in
        # @param window_size [Array(Integer, Integer), nil] the window size Ferrum launched Chrome with
        # @raise [ArgumentError] for a URL pattern that isn't a Regexp, both URL lists, or an unknown device
        def initialize(options, window_size)
          @options = Hash(options)
          @js_errors = @options[:js_errors]
          @pending_connection_errors = @options.fetch(:pending_connection_errors, true)
          @device_user_agent = Devices.fetch(@options[:emulate])[:user_agent] if @options[:emulate]
          @mobile = @options[:mobile]
          @scale_factor = @options.fetch(:scale_factor, 0)
          @initial_window_size = window_size
          reset
        end

        # @return [Boolean] whether JavaScript errors on the page are raised in Ruby
        def js_errors?
          !!@js_errors
        end

        # @return [Boolean] whether `visit` raises {PendingConnectionsError} when the page doesn't load in time
        def pending_connection_errors?
          !!@pending_connection_errors
        end

        # @param patterns [Regexp, Array<Regexp>, nil]
        # @return [void]
        # @raise [ArgumentError] for a pattern that isn't a Regexp, or when a whitelist is set
        def url_blacklist=(patterns)
          patterns = regexp_patterns(patterns)
          raise ArgumentError, "You can't use blacklist along with whitelist" if patterns.any? && url_whitelist.any?

          @url_blacklist = patterns
        end

        # @param patterns [Regexp, Array<Regexp>, nil]
        # @return [void]
        # @raise [ArgumentError] for a pattern that isn't a Regexp, or when a blacklist is set
        def url_whitelist=(patterns)
          patterns = regexp_patterns(patterns)
          raise ArgumentError, "You can't use whitelist along with blacklist" if patterns.any? && url_blacklist.any?

          @url_whitelist = patterns
        end

        # Restores the URL lists, the modal behavior and the window size of the {Driver} options.
        #
        # @return [void]
        def reset
          @raise_on_unhandled_modal = @options[:raise_on_unhandled_modal]
          @window_size = @initial_window_size
          @url_blacklist = @url_whitelist = []
          self.url_blacklist = @options[:url_blacklist]
          self.url_whitelist = @options[:url_whitelist]
        end

        # @return [Boolean] whether an `emulate:` device sets the user agent
        def device_user_agent?
          !@device_user_agent.nil?
        end

        # @param chrome_user_agent [String, nil] Chrome's own user agent
        # @return [String, nil] the emulated device's user agent with Chrome's version, or Chrome's own
        def user_agent(chrome_user_agent)
          return chrome_user_agent unless @device_user_agent

          format(@device_user_agent, version: chrome_user_agent.to_s[%r{Chrome/(\S+)}, 1].to_s)
        end

        private

        def regexp_patterns(patterns)
          Array(patterns).each do |pattern|
            next if pattern.is_a?(Regexp)

            raise ArgumentError, "url_blacklist/url_whitelist take regexps, got #{pattern.inspect}"
          end
        end
      end
    end
  end
end

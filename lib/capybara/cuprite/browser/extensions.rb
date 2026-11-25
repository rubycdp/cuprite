# frozen_string_literal: true

module Capybara
  module Cuprite
    class Browser < Ferrum::Browser
      # Browser settings Cuprite adds to Ferrum, changeable between tests through `page.driver.browser`.
      module Extensions
        # @return [Boolean, nil] whether an unhandled dialog raises {UnhandledModalError} instead of warning
        def raise_on_unhandled_modal
          @options.raise_on_unhandled_modal
        end

        # @param value [Boolean]
        # @return [void]
        def raise_on_unhandled_modal=(value)
          @options.raise_on_unhandled_modal = value
        end

        # @return [Array<Regexp>] the URLs requests are allowed to, all others are blocked
        def url_whitelist
          @options.url_whitelist
        end
        alias url_allowlist url_whitelist

        # Allows requests only to matching URLs, from the current page on.
        #
        # @param patterns [Regexp, Array<Regexp>, nil]
        # @return [void]
        # @raise [ArgumentError] for a pattern that isn't a Regexp
        def url_whitelist=(patterns)
          @options.url_whitelist = regexp_patterns(patterns)
          page.network.whitelist = @options.url_whitelist if @client && @options.url_whitelist.any?
        end
        alias url_allowlist= url_whitelist=

        # @return [Array<Regexp>] the URLs requests to are blocked
        def url_blacklist
          @options.url_blacklist
        end
        alias url_blocklist url_blacklist

        # Blocks requests to matching URLs, from the current page on.
        #
        # @param patterns [Regexp, Array<Regexp>, nil]
        # @return [void]
        # @raise [ArgumentError] for a pattern that isn't a Regexp
        def url_blacklist=(patterns)
          @options.url_blacklist = regexp_patterns(patterns)
          page.network.blacklist = @options.url_blacklist if @client && @options.url_blacklist.any?
        end
        alias url_blocklist= url_blacklist=

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

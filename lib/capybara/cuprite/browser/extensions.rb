# frozen_string_literal: true

module Capybara
  module Cuprite
    class Browser < Ferrum::Browser
      # Browser settings Cuprite adds to Ferrum, changeable between tests through `page.driver.browser`.
      module Extensions
        # @return [Boolean, nil] whether an unhandled dialog raises {UnhandledModalError} instead of warning
        def raise_on_unhandled_modal
          @settings.raise_on_unhandled_modal
        end

        # @param value [Boolean]
        # @return [void]
        def raise_on_unhandled_modal=(value)
          @settings.raise_on_unhandled_modal = value
        end

        # @return [Array<Regexp>] the URLs requests are allowed to, all others are blocked
        def url_whitelist
          @settings.url_whitelist
        end
        alias url_allowlist url_whitelist

        # Allows requests only to matching URLs, from the current page on.
        #
        # @param patterns [Regexp, Array<Regexp>, nil]
        # @return [void]
        # @raise [ArgumentError] for a pattern that isn't a Regexp
        def url_whitelist=(patterns)
          @settings.url_whitelist = patterns
          page.network.whitelist = @settings.url_whitelist if @client && @settings.url_whitelist.any?
        end
        alias url_allowlist= url_whitelist=

        # @return [Array<Regexp>] the URLs requests to are blocked
        def url_blacklist
          @settings.url_blacklist
        end
        alias url_blocklist url_blacklist

        # Blocks requests to matching URLs, from the current page on.
        #
        # @param patterns [Regexp, Array<Regexp>, nil]
        # @return [void]
        # @raise [ArgumentError] for a pattern that isn't a Regexp
        def url_blacklist=(patterns)
          @settings.url_blacklist = patterns
          page.network.blacklist = @settings.url_blacklist if @client && @settings.url_blacklist.any?
        end
        alias url_blocklist= url_blacklist=
      end
    end
  end
end

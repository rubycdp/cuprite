# frozen_string_literal: true

module Capybara
  module Cuprite
    class Driver < Capybara::Driver::Base
      # Driver methods Capybara doesn't need, and settings changeable between tests through `page.driver`.
      module Extensions
        # Opens the current page in DevTools and pauses, taking the arguments of `Ferrum::Browser#debug`.
        #
        # @return [void]
        def debug(...)
          browser.debug(...)
        end

        # @return [Boolean, nil] whether an unhandled dialog raises {UnhandledModalError} instead of warning
        def raise_on_unhandled_modal
          settings.raise_on_unhandled_modal
        end

        # @param value [Boolean]
        # @return [void]
        def raise_on_unhandled_modal=(value)
          settings.raise_on_unhandled_modal = value
        end

        # @return [Array<Regexp>] the URLs requests are allowed to, all others are blocked
        def url_whitelist
          settings.url_whitelist
        end
        alias url_allowlist url_whitelist

        # Allows requests only to matching URLs, from the current page on. An empty list lifts the allowlist from the
        # next page on, the current page keeps the previous one.
        #
        # @param patterns [Regexp, Array<Regexp>, nil]
        # @return [void]
        # @raise [ArgumentError] for a pattern that isn't a Regexp, or when a blocklist is set
        def url_whitelist=(patterns)
          settings.url_whitelist = patterns
          current_page.network.whitelist = settings.url_whitelist if settings.url_whitelist.any?
        end
        alias url_allowlist= url_whitelist=

        # @return [Array<Regexp>] the URLs requests to are blocked
        def url_blacklist
          settings.url_blacklist
        end
        alias url_blocklist url_blacklist

        # Blocks requests to matching URLs, from the current page on. An empty list lifts the blocklist.
        #
        # @param patterns [Regexp, Array<Regexp>, nil]
        # @return [void]
        # @raise [ArgumentError] for a pattern that isn't a Regexp, or when an allowlist is set
        def url_blacklist=(patterns)
          settings.url_blacklist = patterns
          current_page.network.blacklist = settings.url_blacklist
        end
        alias url_blocklist= url_blacklist=
      end
    end
  end
end

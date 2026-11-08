# frozen_string_literal: true

module Capybara
  module Cuprite
    class Browser < Ferrum::Browser
      module Extensions
        def raise_on_unhandled_modal
          @options.raise_on_unhandled_modal
        end

        def raise_on_unhandled_modal=(value)
          @options.raise_on_unhandled_modal = value
        end

        def url_whitelist
          @options.url_whitelist
        end
        alias url_allowlist url_whitelist

        def url_whitelist=(patterns)
          @options.url_whitelist = prepare_wildcards(patterns)
          page.network.whitelist = @options.url_whitelist if @client && @options.url_whitelist.any?
        end
        alias url_allowlist= url_whitelist=

        def url_blacklist
          @options.url_blacklist
        end
        alias url_blocklist url_blacklist

        def url_blacklist=(patterns)
          @options.url_blacklist = prepare_wildcards(patterns)
          page.network.blacklist = @options.url_blacklist if @client && @options.url_blacklist.any?
        end
        alias url_blocklist= url_blacklist=

        private

        def prepare_wildcards(patterns)
          string_passed = false

          Array(patterns).map do |pattern|
            if pattern.is_a?(Regexp)
              pattern
            else
              string_passed = true
              pattern = pattern.gsub("*", ".*")
              Regexp.new(pattern, Regexp::IGNORECASE)
            end
          end
        ensure
          if string_passed
            warn "Passing strings to blacklist/whitelist is deprecated, pass regexp at #{caller(4..4).first}"
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require "capybara/cuprite/deprecation"

module Capybara
  module Cuprite
    class Driver < Capybara::Driver::Base
      # The settings that moved from `page.driver.browser` to `page.driver`. They stay on the browser until 1.0 and
      # forward to the driver with a warning.
      # @api private
      module Deprecations
        # The settings the browser keeps until 1.0.
        BROWSER_METHODS = %i[raise_on_unhandled_modal raise_on_unhandled_modal=
                             url_whitelist url_whitelist= url_allowlist url_allowlist=
                             url_blacklist url_blacklist= url_blocklist url_blocklist=].freeze

        module_function

        # Adds the moved settings to the browser, forwarding them to the driver with a warning. Only this browser
        # object gets them, `Ferrum::Browser` stays as it is.
        #
        # @param browser [Ferrum::Browser]
        # @param driver [Driver]
        # @return [void]
        def extend_browser(browser, driver)
          BROWSER_METHODS.each do |name|
            browser.define_singleton_method(name) do |*args|
              Cuprite.deprecation_warning("page.driver.browser.#{name}", "use page.driver.#{name}")
              driver.public_send(name, *args)
            end
          end
        end
      end
    end
  end
end

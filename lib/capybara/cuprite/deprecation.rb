# frozen_string_literal: true

module Capybara
  module Cuprite
    # The release that removes what's deprecated now.
    REMOVE_DEPRECATED_IN = "1.0"

    # Warns that a method is deprecated, pointing at the code that called it.
    #
    # @api private
    # @param method [String] the deprecated call, e.g. `"page.driver.browser.url_blocklist="`
    # @param advice [String, nil] what to use instead
    # @return [void]
    def self.deprecation_warning(method, advice = nil)
      message = "#{method} is deprecated and will be removed in #{REMOVE_DEPRECATED_IN}"
      message += ", #{advice} instead" if advice
      warn message, uplevel: 2
    end
  end
end

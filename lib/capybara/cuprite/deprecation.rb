# frozen_string_literal: true

module Capybara
  module Cuprite
    REMOVE_DEPRECATED_IN = "0.21"

    def self.deprecation_warning(method, advice = nil)
      message = "#{method} is deprecated and will be removed in #{REMOVE_DEPRECATED_IN}"
      message += ", #{advice} instead" if advice
      warn message, uplevel: 2
    end
  end
end

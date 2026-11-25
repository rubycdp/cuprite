# frozen_string_literal: true

module Capybara
  module Cuprite
    class Driver < Capybara::Driver::Base
      # Driver methods Capybara doesn't need.
      module Extensions
        # Opens the current page in DevTools and pauses, taking the arguments of `Ferrum::Browser#debug`.
        #
        # @return [void]
        def debug(...)
          browser.debug(...)
        end
      end
    end
  end
end

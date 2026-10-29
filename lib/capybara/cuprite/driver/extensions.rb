# frozen_string_literal: true

module Capybara
  module Cuprite
    class Driver < Capybara::Driver::Base
      module Extensions
        def debug(...)
          browser.debug(...)
        end
      end
    end
  end
end

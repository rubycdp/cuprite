# frozen_string_literal: true

require "capybara/cuprite/deprecation"

module Capybara
  module Cuprite
    class Browser < Ferrum::Browser
      module Deprecations
        def visit(*args)
          Cuprite.deprecation_warning("#{self.class}#visit", "use #goto")
          goto(*args)
        end

        def status_code
          Cuprite.deprecation_warning("#{self.class}#status_code", "use #network.status")
          network.status
        end

        def window_handle
          Cuprite.deprecation_warning("#{self.class}#window_handle", "use #current_window_handle")
          current_window_handle
        end
      end
    end
  end
end

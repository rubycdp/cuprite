# frozen_string_literal: true

require "capybara/cuprite/deprecation"

module Capybara
  module Cuprite
    class Node < Capybara::Driver::Node
      module Deprecations
        def browser
          Cuprite.deprecation_warning("#{self.class}#browser", "use page.driver.browser")
          driver.browser
        end

        def parents
          Cuprite.deprecation_warning("#{self.class}#parents", "use Capybara's ancestor")
          command(:parents).map do |parent|
            self.class.new(driver, parent)
          end
        end

        def property(name)
          Cuprite.deprecation_warning("#{self.class}#property", "use node.native.node.property")
          command(:property, name)
        end

        def attributes
          Cuprite.deprecation_warning("#{self.class}#attributes")
          command(:attributes)
        end

        def send_key(*keys)
          Cuprite.deprecation_warning("#{self.class}#send_key", "use #send_keys")
          send_keys(*keys)
        end
      end
    end
  end
end

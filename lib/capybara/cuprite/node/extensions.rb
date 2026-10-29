# frozen_string_literal: true

module Capybara
  module Cuprite
    class Node < Capybara::Driver::Node
      module Extensions
        def drag_by(x, y, **options)
          options[:steps] ||= 1
          options[:scroll] = true unless options.key?(:scroll)

          command(:drag_by, x, y, options[:steps], options[:delay], options[:scroll])
        end
      end
    end
  end
end

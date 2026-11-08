# frozen_string_literal: true

module Capybara
  module Cuprite
    class Node < Capybara::Driver::Node
      module Extensions
        def drag_by(x, y, steps: 1, delay: nil, scroll: true)
          mouse = driver.browser.mouse

          command do
            x1, y1 = node.find_position
            mouse.move(x: x1, y: y1)
            mouse.down

            sleep delay if delay

            mouse.scroll_by(x, y) if scroll

            x2, y2 = node.find_position
            mouse.move(x: x2 + x, y: y2 + y, steps: steps)
            mouse.up
          end
        end
      end
    end
  end
end

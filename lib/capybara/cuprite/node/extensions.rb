# frozen_string_literal: true

module Capybara
  module Cuprite
    class Node < Capybara::Driver::Node
      # Node methods Capybara doesn't need.
      module Extensions
        # Drags the element by an offset with the mouse.
        #
        # @param x [Numeric]
        # @param y [Numeric]
        # @param steps [Integer] mouse moves to reach the target
        # @param delay [Numeric, nil] seconds to wait after pressing the button
        # @param scroll [Boolean] scroll the page by the offset first
        # @return [void]
        # @raise [ObsoleteNode] when the element is no longer in the DOM
        def drag_by(x, y, steps: 1, delay: nil, scroll: true)
          mouse = driver.current_page.mouse

          command do
            x1, y1 = node.pinpoint
            mouse.move(x: x1, y: y1)
            mouse.down

            sleep delay if delay

            mouse.scroll_by(x: x, y: y) if scroll

            x2, y2 = node.pinpoint
            mouse.move(x: x2 + x, y: y2 + y, steps: steps)
            mouse.up
          end
        end
      end
    end
  end
end

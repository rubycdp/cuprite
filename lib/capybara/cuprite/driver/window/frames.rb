# frozen_string_literal: true

module Capybara
  module Cuprite
    class Driver < Capybara::Driver::Base
      class Window
        # Keeps the frame the page's DOM and JavaScript calls run in.
        # @api private
        module Frames
          # @param handle [String, :parent, :top] a frame id, or the parent or top frame
          # @return [void]
          def switch_to_frame(handle)
            case handle
            when :parent
              @frame_stack.pop
            when :top
              @frame_stack = []
            else
              @frame_stack << handle
            end
          end

          # @return [Ferrum::Frame] the frame switched to, the main frame by default
          def active_frame
            if @frame_stack.empty?
              page.main_frame
            else
              page.frame_by(id: @frame_stack.last)
            end
          end
        end
      end
    end
  end
end

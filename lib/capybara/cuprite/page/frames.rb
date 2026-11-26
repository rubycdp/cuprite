# frozen_string_literal: true

require "forwardable"

module Capybara
  module Cuprite
    class Page < Ferrum::Page
      # Runs the page's DOM and JavaScript methods in the frame switched to.
      # @api private
      module Frames
        extend Forwardable

        delegate %i[at_css at_xpath css xpath html execution_id execution_id! evaluate execute] => :active_frame

        def initialize(...)
          @frame_stack = []
          super
        end

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

        private

        def active_frame
          if @frame_stack.empty?
            main_frame
          else
            frame_by(id: @frame_stack.last)
          end
        end
      end
    end
  end
end

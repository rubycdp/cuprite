# frozen_string_literal: true

require "forwardable"

module Capybara
  module Cuprite
    class Page < Ferrum::Page
      module Frames
        extend Forwardable

        delegate %i[at_css at_xpath css xpath
                    current_url current_title body execution_id execution_id!
                    evaluate execute] => :active_frame

        def initialize(...)
          @frame_stack = []
          super
        end

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

        def title
          active_frame.current_title
        end

        private

        def active_frame
          if @frame_stack.empty?
            main_frame
          else
            @frames[@frame_stack.last]
          end
        end
      end
    end
  end
end

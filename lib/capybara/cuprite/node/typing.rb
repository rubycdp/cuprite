# frozen_string_literal: true

module Capybara
  module Cuprite
    class Node < Capybara::Driver::Node
      module Typing
        TYPED_INPUTS = %w[text password email search tel url].freeze
        RAPID_SET_LENGTH = 30
        RAPID_APPEND_TEXT = "this.value = (this.value + value)" \
                            ".slice(0, this.maxLength >= 0 ? this.maxLength : undefined)"

        private

        def set_text(value, rapid: nil, **)
          return command(:set, value) if value.empty?
          return if command { node.evaluate("this.readOnly || this.disabled") }

          value = value.gsub(/\r\n?|\n/, "\r")
          node.focus
          node.evaluate("this.select()")
          middle = value[4...-3].to_s
          if !middle.empty? && (rapid == true || (value.length > RAPID_SET_LENGTH && rapid != false))
            node.type(value[0..3])
            node.evaluate(RAPID_APPEND_TEXT, value: middle)
            node.type(value[-3..])
          else
            node.type(value)
          end
          refocus
        end

        def refocus
          node.evaluate("this.blur(); this.focus()")
        rescue Ferrum::NodeNotFoundError
          nil
        end
      end
    end
  end
end

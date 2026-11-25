# frozen_string_literal: true

module Capybara
  module Cuprite
    class Node < Capybara::Driver::Node
      module Typing
        TYPED_INPUTS = %w[text password email search tel url].freeze
        SET_OPTIONS = %i[rapid clear].freeze
        CLEAR_ERROR = "clear: takes nil, :none, :backspace or an Array of keys"
        RAPID_SET_LENGTH = 30
        RAPID_APPEND_TEXT = "this.value = (this.value + value)" \
                            ".slice(0, this.maxLength >= 0 ? this.maxLength : undefined)"

        private

        def warn_unsupported(options)
          unsupported = options.keys - SET_OPTIONS
          return if unsupported.empty?

          names = unsupported.map(&:inspect).join(", ")
          warn "Options passed to Node#set but Cuprite doesn't support #{names} - ignoring"
        end

        def set_text(value, rapid: nil, clear: nil, **)
          raise ArgumentError, CLEAR_ERROR unless [nil, :none, :backspace].include?(clear) || clear.is_a?(Array)
          return command(:set, value) if value.empty? && clear.nil?
          return if command { node.evaluate("this.readOnly || this.disabled") }

          node.focus
          clear.nil? ? node.evaluate("this.select()") : move_caret_to_end
          keys = clear_keys(clear)
          node.type(*keys) unless keys.empty?
          type_text(value.gsub(/\r\n?|\n/, "\r"), [nil, :none].include?(clear) ? rapid : false)
          refocus
        end

        def clear_keys(clear)
          case clear
          when :backspace then [:backspace] * node.evaluate("this.value.length")
          when Array then clear
          else []
          end
        end

        def type_text(value, rapid)
          middle = value[4...-3].to_s
          if !middle.empty? && (rapid == true || (value.length > RAPID_SET_LENGTH && rapid != false))
            node.type(value[0..3])
            node.evaluate(RAPID_APPEND_TEXT, value: middle)
            node.type(value[-3..])
          elsif !value.empty?
            node.type(value)
          end
        end

        def move_caret_to_end
          if tag_name == "textarea"
            node.evaluate("this.setSelectionRange(this.value.length, this.value.length)")
          else
            node.type(:end)
          end
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

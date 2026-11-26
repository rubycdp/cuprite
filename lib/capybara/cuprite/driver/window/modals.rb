# frozen_string_literal: true

module Capybara
  module Cuprite
    class Driver < Capybara::Driver::Base
      class Window
        # Answers JavaScript dialogs as `accept_modal` and `dismiss_modal` asked, and records their messages.
        # @api private
        module Modals
          # Accepts the next dialog.
          # @return [void]
          def accept_confirm
            @accept_modal << true
          end

          # Dismisses the next dialog.
          # @return [void]
          def dismiss_confirm
            @accept_modal << false
          end

          # Accepts the next dialog with a response.
          # @param modal_response [String, nil]
          # @return [void]
          def accept_prompt(modal_response)
            @accept_modal << true
            @modal_response = modal_response
          end

          # Dismisses the next dialog.
          # @return [void]
          def dismiss_prompt
            @accept_modal << false
          end

          # Waits for a dialog to have been answered.
          #
          # @param options [Hash] `:text` to match and `:wait` in seconds
          # @return [String] the dialog's message
          # @raise [Capybara::ModalNotFound] when no matching dialog was answered in time
          def find_modal(options)
            expect_text = options[:text]
            expect_regexp = expect_text.is_a?(Regexp) ? expect_text : Regexp.escape(expect_text.to_s)
            not_found_msg = "Unable to find modal dialog"
            not_found_msg += " with #{expect_text}" if expect_text
            deadline = monotonic_time + options.fetch(:wait, page.timeout)

            loop do
              remaining = deadline - monotonic_time
              raise Capybara::ModalNotFound, not_found_msg if remaining.negative?

              modal_text = @modal_messages.pop(timeout: remaining)
              return modal_text if modal_text && (!expect_text || modal_text.match?(expect_regexp))
            end
          end

          # Dialogs are answered on Ferrum's background dispatcher thread, where raising wouldn't reach the caller.
          # The error for a dialog nobody expected is stashed there and raised here, on the calling thread, before and
          # after the block.
          #
          # @yield the calls that may open a dialog
          # @return [Object] the block's result
          # @raise [UnhandledModalError] with `raise_on_unhandled_modal` when an unexpected dialog was answered
          def check_modals
            raise_stashed_modal_error
            yield
          ensure
            raise_stashed_modal_error
          end

          private

          def monotonic_time
            Process.clock_gettime(Process::CLOCK_MONOTONIC)
          end

          def raise_stashed_modal_error
            error = @unhandled_modal_error
            @unhandled_modal_error = nil
            raise error if error
          end

          def handle_dialog(dialog)
            accept_modal = @accept_modal.last

            if [true, false].include?(accept_modal)
              @accept_modal.pop
              @modal_messages << dialog.message
              accept = accept_modal
              response = @modal_response
            else
              with_text = dialog.message ? "with text `#{dialog.message}` " : ""
              message = "Modal window #{with_text}has been opened, but you didn't wrap " \
                        "your code into (`accept_prompt` | `dismiss_prompt` | " \
                        "`accept_confirm` | `dismiss_confirm` | `accept_alert`), " \
                        "accepting by default"

              if @settings.raise_on_unhandled_modal
                @unhandled_modal_error = UnhandledModalError.new(message)
              else
                warn message
              end

              accept = true
            end

            accept ? dialog.accept(response) : dialog.dismiss
          end
        end
      end
    end
  end
end

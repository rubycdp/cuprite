# frozen_string_literal: true

module Capybara
  module Cuprite
    class Page < Ferrum::Page
      module Modals
        MODAL_WAIT = ENV.fetch("CUPRITE_MODAL_WAIT", 0.05).to_f

        def initialize(...)
          @accept_modal = []
          @modal_messages = []
          @modal_response = nil
          @unhandled_modal_error = nil
          super
        end

        # Dialogs are handled on Ferrum's background dispatcher thread, so
        # raising there wouldn't reach the caller. The dialog is answered
        # from that thread, skipping the pending error check, and the error
        # (if any) is stashed here to be raised from the calling thread the
        # next time it makes a command round trip.
        def command(...)
          return super if Thread.current[:cuprite_handling_dialog]

          raise_pending_unhandled_modal_error! { super }
        end

        def accept_confirm
          @accept_modal << true
        end

        def dismiss_confirm
          @accept_modal << false
        end

        def accept_prompt(modal_response)
          @accept_modal << true
          @modal_response = modal_response
        end

        def dismiss_prompt
          @accept_modal << false
        end

        def find_modal(options)
          start = Ferrum::Utils::ElapsedTime.monotonic_time
          expect_text = options[:text]
          expect_regexp = expect_text.is_a?(Regexp) ? expect_text : Regexp.escape(expect_text.to_s)
          not_found_msg = "Unable to find modal dialog"
          not_found_msg += " with #{expect_text}" if expect_text
          wait = options.fetch(:wait, timeout)

          begin
            modal_text = @modal_messages.shift
            raise Capybara::ModalNotFound if modal_text.nil? || (expect_text && !modal_text.match(expect_regexp))
          rescue Capybara::ModalNotFound => e
            raise e, not_found_msg if Ferrum::Utils::ElapsedTime.timeout?(start, wait)

            sleep(MODAL_WAIT)
            retry
          end

          modal_text
        end

        private

        def raise_pending_unhandled_modal_error!
          error = @unhandled_modal_error
          @unhandled_modal_error = nil
          raise error if error

          yield
        ensure
          error = @unhandled_modal_error
          @unhandled_modal_error = nil
          raise error if error
        end

        def prepare_page
          super
          on(:dialog) { |dialog| handle_dialog(dialog) }
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

            if @options.raise_on_unhandled_modal
              @unhandled_modal_error = UnhandledModalError.new(message)
            else
              warn message
            end

            accept = true
          end

          answer_dialog(dialog, accept, response)
        end

        def answer_dialog(dialog, accept, response)
          Thread.current[:cuprite_handling_dialog] = true
          accept ? dialog.accept(response) : dialog.dismiss
        ensure
          Thread.current[:cuprite_handling_dialog] = nil
        end
      end
    end
  end
end

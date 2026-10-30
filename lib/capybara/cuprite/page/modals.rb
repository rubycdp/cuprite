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

        # The `Page.javascriptDialogOpening` event is handled on Ferrum's
        # background CDP dispatcher thread, so raising there wouldn't reach
        # the caller and would permanently kill that thread instead. The
        # dialog is always accepted immediately from that thread, and the
        # error (if any) is stashed here to be raised from the main thread
        # the next time it makes a command round trip.
        def command(...)
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
          on("Page.javascriptDialogOpening") { |params| handle_javascript_dialog(params) }
        end

        def handle_javascript_dialog(params)
          accept_modal = @accept_modal.last
          unhandled_modal_error = nil

          if [true, false].include?(accept_modal)
            @accept_modal.pop
            @modal_messages << params["message"]
            options = { accept: accept_modal }
            response = @modal_response || params["defaultPrompt"]
          else
            with_text = params["message"] ? "with text `#{params['message']}` " : ""
            message = "Modal window #{with_text}has been opened, but you didn't wrap " \
                      "your code into (`accept_prompt` | `dismiss_prompt` | " \
                      "`accept_confirm` | `dismiss_confirm` | `accept_alert`), " \
                      "accepting by default"

            if @options.raise_on_unhandled_modal
              unhandled_modal_error = UnhandledModalError.new(message)
            else
              warn message
            end

            options = { accept: true }
            response = params["defaultPrompt"]
          end
          options.merge!(promptText: response) if response
          # Skips #command so a pending error isn't raised on the dispatcher thread.
          client.command("Page.handleJavaScriptDialog", timeout: timeout, **options)

          @unhandled_modal_error = unhandled_modal_error if unhandled_modal_error
        end
      end
    end
  end
end

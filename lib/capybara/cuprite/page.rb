# frozen_string_literal: true

require "forwardable"

module Capybara
  module Cuprite
    class ClosedPage
      def closed?
        true
      end
    end

    class Page < Ferrum::Page
      MODAL_WAIT = ENV.fetch("CUPRITE_MODAL_WAIT", 0.05).to_f
      EXTENSION_JS = File.read(Driver::EXTENSION).freeze

      extend Forwardable

      delegate %i[at_css at_xpath css xpath
                  current_url current_title body execution_id execution_id!
                  evaluate execute] => :active_frame

      def initialize(...)
        @frame_stack = []
        @accept_modal = []
        @modal_messages = []
        @modal_response = nil
        @unhandled_modal_error = nil
        super
      end

      # Keep a handle to Ferrum's own implementation before overriding it
      # below, so answering a dialog (see `handle_javascript_dialog`) can
      # bypass our override.
      alias ferrum_command command

      # The `Page.javascriptDialogOpening` event is handled on Ferrum's
      # background CDP dispatcher thread, so raising there wouldn't reach
      # the caller and would permanently kill that thread instead. The
      # dialog is always accepted immediately from that thread, and the
      # error (if any) is stashed here to be raised from the main thread
      # the next time it makes a command round trip.
      def command(...)
        raise_pending_unhandled_modal_error! { super }
      end

      def set_viewport(width: 0, height: 0, scale_factor: @options.scale_factor, mobile: @options.mobile)
        super
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

      def closed?
        false
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
        execute(EXTENSION_JS)

        width, height = @options.window_size
        width && height ? resize(width: width, height: height) : set_viewport
        command("Network.setUserAgentOverride", userAgent: default_user_agent) if @options.device_user_agent

        if @options.url_blacklist.any?
          network.blacklist = @options.url_blacklist
        elsif @options.url_whitelist.any?
          network.whitelist = @options.url_whitelist
        end

        on("Page.javascriptDialogOpening") do |params|
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
          ferrum_command("Page.handleJavaScriptDialog", **options)

          @unhandled_modal_error = unhandled_modal_error if unhandled_modal_error
        end
      end

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

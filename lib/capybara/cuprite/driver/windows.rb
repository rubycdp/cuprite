# frozen_string_literal: true

module Capybara
  module Cuprite
    class Driver < Capybara::Driver::Base
      # Capybara's windows: Ferrum's page targets, with the one switched to as {Driver#current_page}.
      # @api private
      module Windows
        # @return [Array<String>] the handles of all open windows and tabs
        def window_handles
          browser.targets.values.select(&:page?).map(&:id)
        end

        # @return [String] the handle of the current window
        def current_window_handle
          current_page.target_id
        end

        # Opens a blank page without switching to it.
        #
        # @param kind [:tab, :window] a tab in the current window, or a window of its own
        # @return [Ferrum::Page]
        # @raise [ArgumentError] for any other kind
        def open_new_window(kind = :tab)
          unless %i[tab window].include?(kind)
            raise ArgumentError, "open_new_window takes :tab or :window, got #{kind.inspect}"
          end

          browser.create_page(new_window: kind == :window)
        end

        # Makes a window or tab the current one.
        #
        # @param handle [String]
        # @return [void]
        # @raise [Ferrum::NoSuchPageError] when there's no such window
        def switch_to_window(handle)
          target = window_target(handle)
          forget_page
          @current_page = target.page
          @current_page.activate
        end

        # Closes a window or tab.
        #
        # @param handle [String]
        # @return [void]
        # @raise [Ferrum::NoSuchPageError] when there's no such window
        def close_window(handle)
          target = window_target(handle)
          if @current_page&.target_id == target.id
            forget_page
            @page_closed = true
          end
          browser.close_target(target.id)
          @windows.delete(target.id)
        end

        # @return [Class] the error raised for a closed window
        def no_such_window_error
          Ferrum::NoSuchPageError
        end

        private

        def within_window(handle)
          original = current_window_handle
          raise Ferrum::NoSuchPageError unless window_handles.include?(handle)

          switch_to_window(handle)
          yield
        ensure
          switch_to_window(original)
        end

        def forget_page
          @current_page = nil
          @page_closed = false
        end

        def window_target(handle)
          target = browser.targets[handle]
          raise Ferrum::NoSuchPageError unless target&.page?

          target
        end
      end
    end
  end
end

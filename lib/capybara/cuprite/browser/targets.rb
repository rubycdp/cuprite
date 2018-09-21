# frozen_string_literal: true

module Capybara::Cuprite
  class Browser
    class Targets
      def initialize(browser, logger)
        @mutex = Mutex.new
        @browser, @logger = browser, logger
        @_default = targets.first["targetId"]
        reset
      end

      def push(target_id, page = nil)
        @targets[target_id] = page
      end

      def refresh
        @mutex.synchronize do
          targets.each { |t| push(t["targetId"]) if !default?(t) && !has?(t) }
        end
      end

      def page
        raise NoSuchWindowError unless @page
        @page
      end

      def window_handle
        page.target_id
      end

      def window_handles
        @mutex.synchronize { @targets.keys }
      end

      def switch_to_window(target_id)
        @page = @targets[target_id]
        @page ||= Page.new(target_id, @browser, @logger)
        @targets[target_id] ||= @page
      end

      def open_new_window
        target_id = @browser.command("Target.createTarget", url: "about:blank", browserContextId: @_context_id)["targetId"]
        page = Page.new(target_id, @browser, @logger)
        push(target_id, page)
        target_id
      end

      def close_window(target_id)
        page = @targets.delete(target_id)
        @page = nil if page && @page == page
        page&.close
      end

      def find_window_handle(locator)
        return locator if window_handles.include? locator

        handle = command "window_handle", locator
        raise NoSuchWindowError unless handle
        handle
      end

      def within_window(locator)
        original = window_handle
        handle = find_window_handle(locator)
        switch_to_window(handle)
        yield
      ensure
        switch_to_window(original)
      end

      def reset
        if @page
          @page.close
          @browser.command("Target.disposeBrowserContext", browserContextId: @_context_id)
        end

        @page = nil
        @targets = {}
        @_context_id = nil

        @_context_id = @browser.command("Target.createBrowserContext")["browserContextId"]
        target_id = @browser.command("Target.createTarget", url: "about:blank", browserContextId: @_context_id)["targetId"]
        @page = Page.new(target_id, @browser, @logger)
        push(target_id, @page)
      end

      private

      def targets
        @browser.command("Target.getTargets")["targetInfos"]
      end

      def default?(target)
        @_default == target["targetId"]
      end

      def has?(target)
        @targets.key?(target["targetId"])
      end
    end
  end
end

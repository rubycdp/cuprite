# frozen_string_literal: true

module Capybara::Cuprite
  class Browser
    class Targets
      def initialize(browser, logger)
        @mutex = Mutex.new
        @browser, @logger = browser, logger
        reset

        @default = targets.first
        push(@default)
      end

      def push(target, page: nil)
        target = target.slice("targetId", "browserContextId")
        @targets[target["targetId"]] = target
        @pages[target["targetId"]] = page if page
        true
      end

      def refresh
        @mutex.synchronize do
          targets.reject do |target|
            @targets.key?(target["targetId"])
          end.each { |t| push(t) }
        end
      end

      def page
        @page ||= begin
          page = Page.new(nil, @browser, @logger)
          push(page.target, page: page)
          page
        end
      end


      def window_handle
        @page.target
      end

      def window_handles
        @mutex.synchronize { @targets.values }
      end

      def switch_to_window(target)
        target_id = target["targetId"]
        @page = @pages[target_id]
        @page ||= Page.new(target, @browser, @logger)
        @pages[target_id] = @page
      end

      def open_new_window
        command "open_new_window"
      end

      def close_window(target)
        target_id = target["targetId"]
        @pages[target_id].close
        @pages[target_id] = nil
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
          @browser.command("Target.disposeBrowserContext",
                           browserContextId: @page.context_id)
        end

        @pages, @targets = {}, {}
        @page = nil
      end

      private

      def targets
        @browser.command("Target.getTargets")["targetInfos"]
      end
    end
  end
end

# frozen_string_literal: true

module Capybara::Cuprite
  class Browser
    class Targets
      def initialize(browser)
        @mutex = Mutex.new
        @browser = browser
        @_default = targets.empty? ? nil : targets.first["targetId"]

        @browser.subscribe("Target.detachedFromTarget") do |params|
          page = remove_page(params["targetId"])
          page&.close_connection
        end

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
        page = @targets[target_id]
        page ||= Page.new(target_id, @browser)
        @targets[target_id] ||= page
        @page = page
      end

      def open_new_window
        target_id = @browser.command("Target.createTarget", url: "about:blank", browserContextId: @_context_id)["targetId"]
        page = Page.new(target_id, @browser)
        push(target_id, page)
        target_id
      end

      def close_window(target_id)
        remove_page(target_id)&.close
      end

      def within_window(locator)
        original = window_handle
        if window_handles.include?(locator)
          target_id = locator
        elsif Capybara::VERSION.to_f < 3.0
          target_id = window_handles.find { |target_id| locator == Page.new(target_id, @browser).frame_name }
        end

        if target_id
          switch_to_window(target_id)
          yield
        else
          raise NoSuchWindowError
        end
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
        @page = Page.new(target_id, @browser)
        push(target_id, @page)
      end

      private

      def remove_page(target_id)
        page = @targets.delete(target_id)
        @page = nil if page && @page == page
        page
      end

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

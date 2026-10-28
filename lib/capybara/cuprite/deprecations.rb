# frozen_string_literal: true

module Capybara
  module Cuprite
    module Deprecations
      def self.deprecate(name, replacement)
        define_method(name) do |*args, **kwargs, &block|
          warn "#{self.class}##{name} is deprecated, use ##{replacement} instead", uplevel: 1
          public_send(replacement, *args, **kwargs, &block)
        end
      end
      private_class_method :deprecate

      deprecate :body, :html
      deprecate :window_handle, :current_window_handle
      deprecate :back, :go_back
      deprecate :forward, :go_forward
      deprecate :render, :save_screenshot

      def render_base64(format = :png, options = {})
        warn "#{self.class}#render_base64 is deprecated, use page.driver.browser.screenshot or .pdf instead", uplevel: 1
        browser.screenshot(format: format, encoding: :base64, **options)
      end

      def zoom_factor=(value)
        warn "#{self.class}#zoom_factor= is deprecated, pass scale: to save_screenshot instead", uplevel: 1
        @zoom_factor = value.to_f
      end

      def paper_size=(value)
        warn "#{self.class}#paper_size= is deprecated, pass paper_width: and paper_height: to save_screenshot instead",
             uplevel: 1
        @paper_size = value
      end

      def resize(width, height)
        warn "#{self.class}##{__callee__} is deprecated, use page.current_window.resize_to instead", uplevel: 1
        resize_window_to(current_window_handle, width, height)
      end
      alias resize_window resize

      def authorize(user, password)
        warn "#{self.class}##{__callee__} is deprecated, use page.driver.browser.network.authorize instead", uplevel: 1
        browser.network.authorize(user: user, password: password) do |request, _index, _total|
          request.continue
        end
      end
      alias basic_authorize authorize

      def headers
        warn "#{self.class}#headers is deprecated, use page.driver.browser.headers.get instead", uplevel: 1
        browser.headers.get
      end

      def headers=(headers)
        warn "#{self.class}#headers= is deprecated, use page.driver.browser.headers.set instead", uplevel: 1
        browser.headers.set(headers)
      end

      def add_headers(headers)
        warn "#{self.class}#add_headers is deprecated, use page.driver.browser.headers.add instead", uplevel: 1
        browser.headers.add(headers)
      end

      def add_header(name, value, permanent: true)
        warn "#{self.class}#add_header is deprecated, use page.driver.browser.headers.add instead", uplevel: 1
        browser.headers.add({ name => value }, permanent: permanent)
      end
    end
  end
end

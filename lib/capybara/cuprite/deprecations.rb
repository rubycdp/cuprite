# frozen_string_literal: true

module Capybara
  module Cuprite
    REMOVE_DEPRECATED_IN = "0.21"

    def self.deprecation_warning(method, advice)
      warn "#{method} is deprecated and will be removed in #{REMOVE_DEPRECATED_IN}, #{advice} instead", uplevel: 2
    end

    module Deprecations
      def self.deprecate(name, replacement)
        define_method(name) do |*args, **kwargs, &block|
          Cuprite.deprecation_warning("#{self.class}##{name}", "use ##{replacement}")
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
        Cuprite.deprecation_warning("#{self.class}#render_base64", "use page.driver.browser.screenshot or .pdf")
        browser.screenshot(format: format, encoding: :base64, **options)
      end

      def zoom_factor=(value)
        Cuprite.deprecation_warning("#{self.class}#zoom_factor=", "pass scale: to save_screenshot")
        @zoom_factor = value.to_f
      end

      def paper_size=(value)
        Cuprite.deprecation_warning("#{self.class}#paper_size=",
                                    "pass paper_width: and paper_height: to save_screenshot")
        @paper_size = value
      end

      def resize(width, height)
        Cuprite.deprecation_warning("#{self.class}##{__callee__}", "use page.current_window.resize_to")
        resize_window_to(current_window_handle, width, height)
      end
      alias resize_window resize

      def click(x, y)
        Cuprite.deprecation_warning("#{self.class}#click", "use page.driver.browser.mouse.click")
        browser.mouse.click(x: x, y: y)
      end

      def scroll_to(left, top)
        Cuprite.deprecation_warning("#{self.class}#scroll_to", "use page.scroll_to")
        browser.mouse.scroll_to(left, top)
      end

      def set_proxy(host, port, user = nil, password = nil, bypass = nil)
        Cuprite.deprecation_warning("#{self.class}#set_proxy", "pass the :proxy option to the driver")
        @options.merge!(proxy: { host: host, port: port, user: user, password: password, bypass: bypass })
      end

      def wait_for_reload(timeout = 1)
        Cuprite.deprecation_warning("#{self.class}#wait_for_reload", "use page.driver.browser.wait_for_reload")
        browser.wait_for_reload(timeout)
      end

      def timeout
        Cuprite.deprecation_warning("#{self.class}#timeout", "use page.driver.browser.timeout")
        browser.timeout
      end

      def timeout=(value)
        Cuprite.deprecation_warning("#{self.class}#timeout=", "use page.driver.browser.timeout=")
        browser.timeout = value
      end

      def device_pixel_ratio
        Cuprite.deprecation_warning("#{self.class}#device_pixel_ratio", "use page.driver.browser.device_pixel_ratio")
        browser.device_pixel_ratio
      end

      def viewport_size
        Cuprite.deprecation_warning("#{self.class}#viewport_size", "use page.driver.browser.viewport_size")
        browser.viewport_size
      end

      def authorize(user, password)
        Cuprite.deprecation_warning("#{self.class}##{__callee__}", "use page.driver.browser.network.authorize")
        browser.network.authorize(user: user, password: password) do |request, _index, _total|
          request.continue
        end
      end
      alias basic_authorize authorize

      def headers
        Cuprite.deprecation_warning("#{self.class}#headers", "use page.driver.browser.headers.get")
        browser.headers.get
      end

      def headers=(headers)
        Cuprite.deprecation_warning("#{self.class}#headers=", "use page.driver.browser.headers.set")
        browser.headers.set(headers)
      end

      def add_headers(headers)
        Cuprite.deprecation_warning("#{self.class}#add_headers", "use page.driver.browser.headers.add")
        browser.headers.add(headers)
      end

      def add_header(name, value, permanent: true)
        Cuprite.deprecation_warning("#{self.class}#add_header", "use page.driver.browser.headers.add")
        browser.headers.add({ name => value }, permanent: permanent)
      end

      def cookies
        Cuprite.deprecation_warning("#{self.class}#cookies", "use page.driver.browser.cookies.all")
        browser.cookies.all
      end

      def set_cookie(name, value, options = {})
        Cuprite.deprecation_warning("#{self.class}#set_cookie", "use page.driver.browser.cookies.set")
        options = options.dup
        options[:name]   ||= name
        options[:value]  ||= value
        options[:domain] ||= default_domain
        browser.cookies.set(**options)
      end

      def remove_cookie(name, **options)
        Cuprite.deprecation_warning("#{self.class}#remove_cookie", "use page.driver.browser.cookies.remove")
        options[:domain] = default_domain if options.empty?
        options = options.merge(name: name)
        browser.cookies.remove(**options)
      end

      def clear_cookies
        Cuprite.deprecation_warning("#{self.class}#clear_cookies", "use page.driver.browser.cookies.clear")
        browser.cookies.clear
      end

      def network_traffic(type = nil)
        Cuprite.deprecation_warning("#{self.class}#network_traffic", "use page.driver.browser.network.traffic")
        traffic = browser.network.traffic

        case type.to_s
        when "all"
          traffic
        when "blocked"
          traffic.select(&:blocked?)
        else
          # when request isn't blocked
          traffic.reject(&:blocked?)
        end
      end

      def clear_network_traffic
        Cuprite.deprecation_warning("#{self.class}#clear_network_traffic",
                                    "use page.driver.browser.network.clear(:traffic)")
        browser.network.clear(:traffic)
      end

      def wait_for_network_idle(**options)
        Cuprite.deprecation_warning("#{self.class}#wait_for_network_idle",
                                    "use page.driver.browser.network.wait_for_idle")
        browser.network.wait_for_idle(**options)
      end

      def clear_memory_cache
        Cuprite.deprecation_warning("#{self.class}#clear_memory_cache", "use page.driver.browser.network.clear(:cache)")
        browser.network.clear(:cache)
      end

      private

      def default_domain
        if @started
          URI.parse(browser.current_url).host
        else
          URI.parse(default_cookie_host).host || "127.0.0.1"
        end
      end

      def default_cookie_host
        if respond_to?(:session_options)
          session_options.app_host
        else
          Capybara.app_host
        end || ""
      end
    end
  end
end

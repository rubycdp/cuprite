# frozen_string_literal: true

require "uri"
require "forwardable"
require "capybara/cuprite/deprecations"

module Capybara
  module Cuprite
    class Driver < Capybara::Driver::Base
      DEFAULT_MAXIMIZE_SCREEN_SIZE = [1366, 768].freeze
      EXTENSION = File.expand_path("javascripts/index.js", __dir__)

      extend Forwardable
      include Deprecations

      delegate %i[restart quit status_code current_url title
                  window_handles current_window_handle close_window switch_to_window within_window
                  refresh] => :browser
      delegate %i[send_keys] => :active_element
      def_delegator :browser, :body, :html
      def_delegator :browser, :back, :go_back
      def_delegator :browser, :forward, :go_forward

      attr_reader :app, :options

      def initialize(app, options = {})
        @app     = app
        @options = options.dup
        @started = false

        @options[:extensions] ||= []
        @options[:extensions] << EXTENSION

        @screen_size = @options.delete(:screen_size)
        @screen_size ||= DEFAULT_MAXIMIZE_SCREEN_SIZE
        @options[:save_path] ||= File.expand_path(Capybara.save_path) if Capybara.save_path

        @options[:pending_connection_errors] = true unless @options.key?(:pending_connection_errors)

        # It's set for debug() to make devtools tab open correctly.
        @options[:browser_options] ||= {}
        unless @options[:browser_options][:"remote-allow-origins"]
          @options[:browser_options].merge!("remote-allow-origins": "*")
        end
        @options[:browser_options] = { "disable-web-security": nil }.merge(@options[:browser_options])

        super()
      end

      def needs_server?
        true
      end

      def browser
        @browser ||= Browser.new({ base_url: capybara_base_url }.compact.merge(@options))
      end

      def visit(url)
        @started = true
        browser.base_url = url if url.match?(%r{\Ahttps?://})
        browser.visit(url)
      end

      def frame_url
        evaluate_script("window.location.href")
      end

      def frame_title
        evaluate_script("document.title")
      end

      def active_element
        Node.new(self, browser.active_element)
      end

      def find_xpath(selector)
        find(:xpath, selector)
      end

      def find_css(selector)
        find(:css, selector)
      end

      def evaluate_script(script, *args)
        result = browser.evaluate(script, *native_args(args))
        unwrap_script_result(result)
      end

      def evaluate_async_script(script, *args)
        result = browser.evaluate_async(script, session_wait_time, *native_args(args))
        unwrap_script_result(result)
      end

      def execute_script(script, *args)
        browser.execute(script, *native_args(args))
        nil
      end

      def switch_to_frame(locator)
        handle = case locator
                 when Capybara::Node::Element
                   locator.native.node.description["frameId"]
                 when Capybara::Cuprite::Node
                   locator.node.description["frameId"]
                 when :parent, :top
                   locator
                 end

        raise ArgumentError, "Unable to switch to frame from #{locator.class}" unless handle

        browser.page.switch_to_frame(handle)
      end

      def open_new_window
        target = browser.default_context.create_target
        target.maybe_sleep_if_new_window
        target.page = Page.new(target.client, context_id: target.context_id, target_id: target.id)
        target.page
      end

      def no_such_window_error
        Ferrum::NoSuchPageError
      end

      def reset!
        @zoom_factor = nil
        @paper_size = nil
        browser.url_blacklist = @options[:url_blacklist]
        browser.url_whitelist = @options[:url_whitelist]
        browser.raise_on_unhandled_modal = @options.fetch(:raise_on_unhandled_modal, false)
        browser.reset
        base_url = @options[:base_url] || capybara_base_url
        browser.base_url = base_url if base_url
      ensure
        @started = false
      end

      def save_screenshot(path, options = {})
        options[:scale] = @zoom_factor if @zoom_factor

        if File.extname(path) == ".pdf"
          options[:paperWidth] = @paper_size[:width].to_f if @paper_size
          options[:paperHeight] = @paper_size[:height].to_f if @paper_size
          browser.pdf(path: path, **options)
        else
          browser.screenshot(path: path, **options)
        end
      end

      def resize_window_to(handle, width, height)
        within_window(handle) do
          browser.resize(width: width, height: height)
        end
      end

      def maximize_window(handle)
        resize_window_to(handle, *screen_size)
      end

      def window_size(handle)
        within_window(handle) do
          evaluate_script("[window.innerWidth, window.innerHeight]")
        end
      end

      def fullscreen_window(handle)
        within_window(handle) do
          browser.resize(fullscreen: true)
        end
      end

      def response_headers
        browser.network.response&.headers
      end

      def debug(...)
        browser.debug(...)
      end

      def wait?
        true
      end

      def invalid_element_errors
        [Capybara::Cuprite::ObsoleteNode,
         Capybara::Cuprite::MouseEventFailed,
         Ferrum::CoordinatesNotFoundError,
         Ferrum::NoExecutionContextError,
         Ferrum::NodeNotFoundError]
      end

      def accept_modal(type, options = {})
        case type
        when :alert, :confirm
          browser.page.accept_confirm
        when :prompt
          browser.page.accept_prompt(options[:with])
        end

        yield if block_given?

        browser.page.find_modal(options)
      end

      def dismiss_modal(type, options = {})
        case type
        when :confirm
          browser.page.dismiss_confirm
        when :prompt
          browser.page.dismiss_prompt
        end

        yield if block_given?

        browser.page.find_modal(options)
      end

      private

      attr_reader :screen_size

      def find(method, selector)
        browser.find(method, selector).map { |native| Node.new(self, native) }
      end

      def capybara_base_url
        session_options.app_host || session&.server&.base_url
      end

      def native_args(args)
        args.map { |arg| arg.is_a?(Capybara::Cuprite::Node) ? arg.node : arg }
      end

      def session_wait_time
        if respond_to?(:session_options)
          session_options.default_max_wait_time
        else
          begin
            Capybara.default_max_wait_time
          rescue StandardError
            Capybara.default_wait_time
          end
        end
      end

      def unwrap_script_result(arg)
        case arg
        when Array
          arg.map { |e| unwrap_script_result(e) }
        when Hash
          arg.each { |k, v| arg[k] = unwrap_script_result(v) }
        when Ferrum::Node
          Node.new(self, arg)
        else
          arg
        end
      end
    end
  end
end

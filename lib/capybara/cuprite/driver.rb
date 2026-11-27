# frozen_string_literal: true

require "forwardable"
require "rack"
require "capybara/cuprite/finder"
require "capybara/cuprite/driver/deprecations"
require "capybara/cuprite/driver/extensions"
require "capybara/cuprite/driver/settings"
require "capybara/cuprite/driver/window"
require "capybara/cuprite/driver/windows"

module Capybara
  module Cuprite
    # Capybara driver for Chrome, built on Ferrum.
    #
    # The driver keeps what Capybara needs and Ferrum doesn't have, and leaves the rest to a plain Ferrum browser:
    #
    #   Driver
    #   ├─ browser       Ferrum::Browser
    #   │  └─ on_page    sets up every new page: Cuprite's JS, viewport, user agent, URL lists, JS errors
    #   ├─ current_page  Ferrum::Page of Capybara's current window
    #   ├─ window        Window, that window's frames and dialogs
    #   │  ├─ Frames     the frame switched to, current_frame
    #   │  └─ Modals     the dialogs to answer, the unhandled dialog error
    #   ├─ Windows       window handles, opening, switching, closing
    #   ├─ Settings      the options only Cuprite handles
    #   └─ Extensions    debug, URL lists, raise_on_unhandled_modal
    #
    #   Node wraps a Ferrum::Node and works in current_frame and current_page, Finder finds nodes in a frame.
    #
    # @example Register the driver
    #   Capybara.register_driver(:cuprite) do |app|
    #     Capybara::Cuprite::Driver.new(app, window_size: [1200, 800])
    #   end
    class Driver < Capybara::Driver::Base
      # The window size `maximize_window` resizes to unless `screen_size:` is given.
      DEFAULT_MAXIMIZE_SCREEN_SIZE = [1366, 768].freeze
      # The path of the JavaScript Cuprite adds to every page.
      # @api private
      EXTENSION = File.expand_path("javascripts/index.js", __dir__)
      # The JavaScript Cuprite adds to every page.
      # @api private
      EXTENSION_JS = File.read(EXTENSION).freeze
      # The options Cuprite handles itself and doesn't pass to Ferrum.
      # @api private
      CUPRITE_OPTIONS = %i[js_errors pending_connection_errors].freeze
      # The case-insensitive Hash class `response_headers` returns.
      # @api private
      RESPONSE_HEADERS = defined?(Rack::Headers) ? Rack::Headers : Rack::Utils::HeaderHash
      # The wrapper that turns an async script's callback into a Promise.
      # @api private
      CALLBACK_JS = <<~JS
        function(...args) {
          return new Promise((resolve, reject) => {
            try {
              (function() {
                SCRIPT
              }).apply(this, [...args, resolve]);
            } catch (error) {
              reject(error);
            }
          });
        }
      JS

      extend Forwardable
      include Extensions
      include Windows

      # @!method title
      #   @return [String] the title of the current page
      # @!method refresh
      #   Reloads the current page.
      #   @return [void]
      delegate %i[title refresh] => :current_page
      # @!method send_keys(*keys)
      #   Types keys into the focused element, see {Node#send_keys}.
      #   @param keys [Array<String, Symbol, Array>]
      #   @return [void]
      delegate %i[send_keys] => :active_element
      # @!method current_url
      #   @return [String] the URL of the current page
      def_delegator :current_page, :url, :current_url
      # @!method html
      #   @return [String] the HTML of the current page or frame
      delegate %i[html] => :current_frame
      # @!method go_back
      #   Navigates back in history.
      #   @return [void]
      def_delegator :current_page, :back, :go_back
      # @!method go_forward
      #   Navigates forward in history.
      #   @return [void]
      def_delegator :current_page, :forward, :go_forward

      # @return [#call] the Rack application under test
      attr_reader :app
      # @return [Hash] the options the browser is started with
      attr_reader :options

      # Every Ferrum option is accepted as well, see Ferrum's docs.
      #
      # @param app [#call] the Rack application under test
      # @param options [Hash]
      # @option options [Boolean] :js_errors re-raise JavaScript errors from the page as `Ferrum::JavaScriptError`,
      #   `false` by default
      # @option options [Boolean] :pending_connection_errors raise {PendingConnectionsError} from `visit` when the
      #   page doesn't load in time, `true` by default
      # @option options [Array(Integer, Integer)] :screen_size the size `maximize_window` resizes to,
      #   {DEFAULT_MAXIMIZE_SCREEN_SIZE} by default
      # @option options [Boolean] :raise_on_unhandled_modal raise {UnhandledModalError} instead of warning when a
      #   dialog isn't handled, `false` by default
      # @option options [Array<Regexp>] :url_blocklist requests to block, alias `:url_blacklist`
      # @option options [Array<Regexp>] :url_allowlist requests to allow, alias `:url_whitelist`
      # @option options [Symbol] :emulate a device from {Devices::LIST} to emulate
      # @option options [Boolean] :mobile emulate a mobile device, `false` by default
      # @option options [Numeric] :scale_factor the device scale factor to emulate, `0` (browser default) by default
      def initialize(app, options = {})
        @app     = app
        @options = options.dup
        @started = false
        @current_page = nil
        @page_closed = false
        @windows = {}

        @options[:extensions] ||= []
        @options[:extensions] << EXTENSION

        @screen_size = @options.delete(:screen_size)
        @screen_size ||= DEFAULT_MAXIMIZE_SCREEN_SIZE
        @options[:save_path] ||= File.expand_path(Capybara.save_path) if Capybara.save_path

        @options[:url_blacklist] = @options.delete(:url_blocklist) if @options.key?(:url_blocklist)
        @options[:url_whitelist] = @options.delete(:url_allowlist) if @options.key?(:url_allowlist)

        # It's set for debug() to make devtools tab open correctly.
        @options[:browser_options] ||= {}
        unless @options[:browser_options][:"remote-allow-origins"]
          @options[:browser_options].merge!("remote-allow-origins": "*")
        end
        @options[:browser_options] = { "disable-web-security": nil }.merge(@options[:browser_options])

        super()
      end

      # @return [true] Cuprite runs the app in a server
      def needs_server?
        true
      end

      # The Ferrum browser, started on first use. Reach for it for browser-wide settings such as `timeout`, and for
      # pages through {#current_page}.
      #
      # @return [Ferrum::Browser]
      # @raise [ArgumentError] for a URL pattern that isn't a Regexp, both URL lists, or an unknown device
      def browser
        @browser ||= start_browser
      end

      # The Ferrum page of Capybara's current window, the one it's switched to at the moment. The driver runs Capybara's
      # calls on it, and it's the way to use Ferrum in that window, because `browser.page` is always the first window,
      # even inside `within_window`.
      #
      # @example
      #   within_window(new_window) { page.driver.current_page.network.traffic }
      #
      # @return [Ferrum::Page] the first window's page until Capybara switches to another one
      # @raise [Ferrum::NoSuchPageError] when the current window was closed
      def current_page
        raise Ferrum::NoSuchPageError if @page_closed

        @current_page ||= browser.page
      end

      # @api private
      # @return [Window] the frames and dialogs Cuprite keeps for the current window
      def window
        @windows.fetch(current_page.target_id)
      end

      # @api private
      # @return [Ferrum::Frame] the frame switched to in the current page
      def current_frame
        window.current_frame
      end

      # Navigates to a URL, relative ones against Capybara's `app_host` or server.
      #
      # @param url [String]
      # @return [void]
      # @raise [PendingConnectionsError] with `pending_connection_errors` when the page doesn't load in time
      def visit(url)
        @started = true
        browser.base_url = url if url.match?(%r{\Ahttps?://})
        check_modals { navigate(url) }
      end

      # @return [Integer, nil] the HTTP status of the last response
      def status_code
        current_page.network.status
      end

      # @return [String] the URL of the current frame
      def frame_url
        evaluate_script("window.location.href")
      end

      # @return [String] the title of the current frame
      def frame_title
        evaluate_script("document.title")
      end

      # @return [Node] the focused element
      def active_element
        Node.new(self, current_frame.evaluate("document.activeElement"))
      end

      # @param selector [String]
      # @param hints [Hash] Capybara's finder hints
      # @return [Array<Node>] the elements matching the XPath
      # @raise [InvalidSelector]
      def find_xpath(selector, **hints)
        find(:xpath, selector, **hints)
      end

      # @param selector [String]
      # @param hints [Hash] Capybara's finder hints
      # @return [Array<Node>] the elements matching the CSS selector
      # @raise [InvalidSelector]
      def find_css(selector, **hints)
        find(:css, selector, **hints)
      end

      # Evaluates a JavaScript expression, with `arguments` set to `args`.
      #
      # @param script [String]
      # @param args [Array] values passed to the script, nodes as elements
      # @return [Object] the result, elements as {Node}
      def evaluate_script(script, *args)
        result = check_modals { current_frame.evaluate(script, *native_args(args)) }
        unwrap_script_result(result)
      end

      # Evaluates JavaScript that calls the callback passed as its last argument, waiting up to Capybara's
      # `default_max_wait_time`.
      #
      # @param script [String]
      # @param args [Array] values passed to the script, nodes as elements
      # @return [Object] the value passed to the callback, elements as {Node}
      def evaluate_async_script(script, *args)
        result = check_modals do
          current_frame.evaluate(CALLBACK_JS.sub("SCRIPT") { script }, *native_args(args), timeout: session_wait_time)
        end
        unwrap_script_result(result)
      end

      # Executes JavaScript, with `arguments` set to `args`.
      #
      # @param script [String]
      # @param args [Array] values passed to the script, nodes as elements
      # @return [nil]
      def execute_script(script, *args)
        check_modals { current_frame.execute(script, *native_args(args)) }
        nil
      end

      # @param locator [Capybara::Node::Element, Node, :parent, :top] the frame element, or the parent or top frame
      # @return [void]
      # @raise [ArgumentError] for any other locator
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

        window.switch_to_frame(handle)
      end

      # Closes the browser.
      #
      # @return [void]
      def quit
        @browser&.quit
      ensure
        @windows.clear
        forget_page
      end

      # Resets the browser between tests: starts a fresh browser context and restores the options.
      #
      # @return [void]
      def reset!
        return unless @browser

        reset_browser
        base_url = @options[:base_url] || capybara_base_url
        browser.base_url = base_url if base_url
      ensure
        @started = false
      end

      # Saves a screenshot, or a PDF when the path ends in `.pdf`.
      #
      # @param path [String]
      # @param options [Hash] the options of Ferrum's `screenshot` or `pdf`, like `full:` or `selector:`
      # @return [void]
      def save_screenshot(path, options = {})
        if File.extname(path) == ".pdf"
          current_page.pdf(path: path, **options)
        else
          current_page.screenshot(path: path, **options)
        end
      end

      # @param handle [String]
      # @param width [Integer]
      # @param height [Integer]
      # @return [void]
      # @raise [Ferrum::NoSuchPageError] when there's no such window
      def resize_window_to(handle, width, height)
        within_window(handle) do
          settings.window_size = [width, height]
          current_page.resize(width: width, height: height)
          emulate_viewport(current_page, width, height)
        end
      end

      # Resizes a window to `screen_size:`.
      #
      # @param handle [String]
      # @return [void]
      # @raise [Ferrum::NoSuchPageError] when there's no such window
      def maximize_window(handle)
        resize_window_to(handle, *screen_size)
      end

      # @param handle [String]
      # @return [Array(Integer, Integer)] the inner width and height of the window
      # @raise [Ferrum::NoSuchPageError] when there's no such window
      def window_size(handle)
        within_window(handle) do
          evaluate_script("[window.innerWidth, window.innerHeight]")
        end
      end

      # @param handle [String]
      # @return [void]
      # @raise [Ferrum::NoSuchPageError] when there's no such window
      def fullscreen_window(handle)
        within_window(handle) do
          settings.window_size = [nil, nil]
          current_page.resize(fullscreen: true)
          emulate_viewport(current_page, *current_page.document_size)
        end
      end

      # The headers of the last response, looked up case-insensitively as with rack_test.
      #
      # @return [Hash{String => String}, nil] `Rack::Headers`, or `Rack::Utils::HeaderHash` on Rack 2
      def response_headers
        headers = current_page.network.response&.headers
        RESPONSE_HEADERS[headers] if headers
      end

      # @return [true] Capybara waits for elements with Cuprite
      def wait?
        true
      end

      # @return [Array<Class>] the errors after which Capybara looks the element up again
      def invalid_element_errors
        [Capybara::Cuprite::ObsoleteNode,
         Capybara::Cuprite::MouseEventFailed,
         Ferrum::CoordinatesNotFoundError,
         Ferrum::NoExecutionContextError,
         Ferrum::NodeNotFoundError]
      end

      # Accepts the dialog the block opens.
      #
      # @param type [:alert, :confirm, :prompt]
      # @param options [Hash]
      # @option options [String, Regexp] :text the text the dialog has to match
      # @option options [String] :with the response to a prompt
      # @option options [Numeric] :wait how long to wait for the dialog
      # @yield the action that opens the dialog
      # @return [String] the dialog's message
      # @raise [Capybara::ModalNotFound] when no matching dialog opens in time
      def accept_modal(type, options = {})
        case type
        when :alert, :confirm
          window.accept_confirm
        when :prompt
          window.accept_prompt(options[:with])
        end

        yield if block_given?

        window.find_modal(options)
      end

      # Dismisses the dialog the block opens.
      #
      # @param type [:confirm, :prompt]
      # @param options [Hash]
      # @option options [String, Regexp] :text the text the dialog has to match
      # @option options [Numeric] :wait how long to wait for the dialog
      # @yield the action that opens the dialog
      # @return [String] the dialog's message
      # @raise [Capybara::ModalNotFound] when no matching dialog opens in time
      def dismiss_modal(type, options = {})
        case type
        when :confirm
          window.dismiss_confirm
        when :prompt
          window.dismiss_prompt
        end

        yield if block_given?

        window.find_modal(options)
      end

      private

      attr_reader :screen_size

      def find(method, selector, **hints)
        nodes = check_modals { Finder.find(current_frame, method, selector, **hints) }
        nodes.map { |native, cache| Node.new(self, native, cache) }
      end

      def check_modals(&)
        window.check_modals(&)
      end

      def start_browser
        options = { base_url: capybara_base_url }.compact.merge(@options)
        device = options[:emulate]
        options = Devices.fetch(device).except(:user_agent).merge(options) if device

        browser = Ferrum::Browser.new(options.except(*CUPRITE_OPTIONS))
        @settings = Settings.new(options, browser.options.window_size)
        browser.on_page { |page| prepare_page(page) }
        Deprecations.extend_browser(browser, self)
        browser
      rescue StandardError
        browser&.quit
        raise
      end

      def reset_browser
        @windows.clear
        browser.reset
      rescue Ferrum::DeadBrowserError
        browser.restart
      ensure
        @settings.reset
        forget_page
      end

      def settings
        browser
        @settings
      end

      def navigate(url)
        return current_page.go_to(url) unless settings.pending_connection_errors?

        current_page.go_to!(url)
      rescue Ferrum::NavigationTimeoutError => e
        raise if Ferrum::Deadline.current&.expired?

        raise PendingConnectionsError.new(e.url, e.pendings)
      end

      def prepare_page(page)
        @windows[page.target_id] = Window.new(page, @settings)
        subscribe_to_js_errors(page) if @settings.js_errors?
        page.execute(EXTENSION_JS)

        width, height = @settings.window_size
        page.resize(width: width, height: height) if width && height
        emulate_viewport(page, width, height)
        emulate_device_user_agent(page) if @settings.device_user_agent?

        page.network.blacklist = @settings.url_blacklist if @settings.url_blacklist.any?
        page.network.whitelist = @settings.url_whitelist if @settings.url_whitelist.any?
      end

      def subscribe_to_js_errors(page)
        page.on("Runtime.exceptionThrown") do |params|
          Thread.main.raise Ferrum::JavaScriptError, params["exceptionDetails"]
        end
      end

      def emulate_viewport(page, width, height)
        page.set_viewport(width: width || 0, height: height || 0, scale_factor: @settings.scale_factor,
                          mobile: @settings.mobile)
      end

      def emulate_device_user_agent(page)
        page.network.emulate(user_agent: @settings.user_agent(browser.default_user_agent))
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

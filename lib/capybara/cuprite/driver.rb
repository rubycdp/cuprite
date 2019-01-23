# frozen_string_literal: true

require "uri"

require "forwardable"

module Capybara::Cuprite
  class Driver < Capybara::Driver::Base
    extend Forwardable

    delegate %i(restart quit status_code timeout timeout=) => :browser

    attr_reader :app, :options

    def initialize(app, options = {})
      @app     = app
      @options = options.freeze
      @started = false
    end

    def needs_server?
      true
    end

    def browser
      @browser ||= Browser.start(@options)
    end

    def visit(url)
      @started = true
      browser.visit(url)
    end

    def current_url
      if Capybara::VERSION.to_f < 3.0
        frame_url
      else
        browser.current_url
      end
    end

    def frame_url
      browser.frame_url
    end

    def html
      browser.body
    end
    alias_method :body, :html

    def source
      browser.source.to_s
    end

    def title
      if Capybara::VERSION.to_f < 3.0
        frame_title
      else
        browser.title
      end
    end

    def frame_title
      browser.frame_title
    end

    def find(method, selector)
      browser.find(method, selector).map { |target_id, node| Node.new(self, target_id, node) }
    end

    def find_xpath(selector)
      find :xpath, selector
    end

    def find_css(selector)
      find :css, selector
    end

    def click(x, y)
      browser.click_coordinates(x, y)
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
      browser.switch_to_frame(locator)
    end

    def current_window_handle
      browser.window_handle
    end

    def window_handles
      browser.window_handles
    end

    def close_window(handle)
      browser.close_window(handle)
    end

    def open_new_window
      browser.open_new_window
    end

    def switch_to_window(handle)
      browser.switch_to_window(handle)
    end

    def within_window(name, &block)
      browser.within_window(name, &block)
    end

    def no_such_window_error
      NoSuchWindowError
    end

    def reset!
      browser.reset
      browser.url_blacklist = @options[:url_blacklist] if @options.key?(:url_blacklist)
      browser.url_whitelist = @options[:url_whitelist] if @options.key?(:url_whitelist)
      @started = false
    end

    def save_screenshot(path, options = {})
      browser.render(path, options)
    end
    alias_method :render, :save_screenshot

    def render_base64(format = :png, options = {})
      browser.render_base64(format, options)
    end

    def paper_size=(size = {})
      browser.set_paper_size(size)
    end

    def zoom_factor=(zoom_factor)
      browser.set_zoom_factor(zoom_factor)
    end

    def resize(width, height)
      browser.resize(width, height)
    end
    alias_method :resize_window, :resize

    def resize_window_to(handle, width, height)
      within_window(handle) do
        resize(width, height)
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

    def scroll_to(left, top)
      browser.scroll_to(left, top)
    end

    def network_traffic(type = nil)
      browser.network_traffic(type)
    end

    def clear_network_traffic
      browser.clear_network_traffic
    end

    def set_proxy(ip, port, type = "http", user = nil, password = nil)
      browser.set_proxy(ip, port, type, user, password)
    end

    def headers
      browser.headers
    end

    def headers=(headers)
      browser.headers=(headers)
    end

    def add_headers(headers)
      browser.add_headers(headers)
    end

    def add_header(name, value, permanent: true)
      browser.add_header({ name => value }, permanent: permanent)
    end

    def response_headers
      browser.response_headers
    end

    def cookies
      browser.cookies
    end

    def set_cookie(name, value, options = {})
      options = options.dup
      options[:name]   ||= name
      options[:value]  ||= value
      options[:domain] ||= default_domain

      expires = options.delete(:expires).to_i
      options[:expires] = expires if expires > 0

      browser.set_cookie(options)
    end

    def remove_cookie(name, **options)
      options[:domain] = default_domain if options.empty?
      browser.remove_cookie(options.merge(name: name))
    end

    def clear_cookies
      browser.clear_cookies
    end

    def clear_memory_cache
      browser.clear_memory_cache
    end

    # * Browser with set settings does not send `Authorize` on POST request
    # * With manually set header browser makes next request with
    # `Authorization: Basic Og==` header when settings are empty and the
    # response was `401 Unauthorized` (which means Base64.encode64(":")).
    # Combining both methods to reach proper behavior.
    def basic_authorize(user, password)
      browser.set_http_auth(user, password)
      credentials = ["#{user}:#{password}"].pack("m*").strip
      add_header("Authorization", "Basic #{credentials}")
    end

    def pause
      # STDIN is not necessarily connected to a keyboard. It might even be closed.
      # So we need a method other than keypress to continue.

      # In jRuby - STDIN returns immediately from select
      # see https://github.com/jruby/jruby/issues/1783
      read, write = IO.pipe
      Thread.new { IO.copy_stream(STDIN, write); write.close }

      STDERR.puts "Cuprite execution paused. Press enter (or run 'kill -CONT #{Process.pid}') to continue."

      signal = false
      old_trap = trap("SIGCONT") { signal = true; STDERR.puts "\nSignal SIGCONT received" }
      keyboard = IO.select([read], nil, nil, 1) until keyboard || signal # wait for data on STDIN or signal SIGCONT received

      unless signal
        begin
          input = read.read_nonblock(80) # clear out the read buffer
          puts unless input&.end_with?("\n")
        rescue EOFError, IO::WaitReadable # Ignore problems reading from STDIN.
        end
      end
    ensure
      trap("SIGCONT", old_trap) # Restore the previous signal handler, if there was one.
      STDERR.puts "Continuing"
    end

    def wait?
      true
    end

    def invalid_element_errors
      [Capybara::Cuprite::ObsoleteNode, Capybara::Cuprite::MouseEventFailed]
    end

    def go_back
      browser.go_back
    end

    def go_forward
      browser.go_forward
    end

    def refresh
      browser.refresh
    end

    def accept_modal(type, options = {})
      case type
      when :alert, :confirm
        browser.accept_confirm
      when :prompt
        browser.accept_prompt(options[:with])
      end

      yield if block_given?

      browser.find_modal(options)
    end

    def dismiss_modal(type, options = {})
      case type
      when :confirm
        browser.dismiss_confirm
      when :prompt
        browser.dismiss_prompt
      end

      yield if block_given?

      browser.find_modal(options)
    end

    private

    def default_domain
      if @started
        URI.parse(browser.current_url).host
      else
        URI.parse(default_cookie_host).host || "127.0.0.1"
      end
    end

    def native_args(args)
      args.map { |arg| arg.is_a?(Capybara::Cuprite::Node) ? arg.native : arg }
    end

    def screen_size
      @options[:screen_size] || [1366, 768]
    end

    def session_wait_time
      if respond_to?(:session_options)
        session_options.default_max_wait_time
      else
        begin
          Capybara.default_max_wait_time
        rescue
          Capybara.default_wait_time
        end
      end
    end

    def default_cookie_host
      if respond_to?(:session_options)
        session_options.app_host
      else
        Capybara.app_host
      end || ""
    end

    def unwrap_script_result(arg)
      case arg
      when Array
        arg.map { |e| unwrap_script_result(e) }
      when Hash
        return Capybara::Cuprite::Node.new(self, arg["target_id"], arg["node"]) if arg["target_id"]
        arg.each { |k, v| arg[k] = unwrap_script_result(v) }
      else
        arg
      end
    end
  end
end

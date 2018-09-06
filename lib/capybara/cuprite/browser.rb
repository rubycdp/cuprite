# frozen_string_literal: true

require "base64"
require "forwardable"
require "cuprite/browser/process"
require "cuprite/browser/client"
require "cuprite/browser/page"

module Capybara::Cuprite
  class Browser
    extend Forwardable

    class NullLogger
      def write(_message)
      end
    end

    def self.start(*args)
      new(*args)
    end

    attr_reader :process
    delegate [:command, :wait] => :@client

    def initialize(options = nil)
      options ||= {}
      @process = Process.start(options)
      @logger = options.fetch(:logger, NullLogger.new)
      @client = Client.new(@process.ws_url, @logger)
      reset
    end

    def visit(url)
      @page.visit(url)
    end

    def current_url
      response = @page.command("Runtime.evaluate", expression: "location.href")
      response["result"]["value"]
    end

    def frame_url
      command "frame_url"
    end

    def status_code
      command "status_code"
    end

    def body
      response = @page.command("DOM.getDocument", depth: 0)
      response = @page.command("DOM.getOuterHTML", nodeId: response["root"]["nodeId"])
      response["outerHTML"]
    end

    def source
      command "source"
    end

    def title
      command "title"
    end

    def frame_title
      command "frame_title"
    end

    def parents(page_id, id)
      command "parents", page_id, id
    end

    def find(_, selector)
      results = []
      response = @page.command("DOM.performSearch", query: selector)
      search_id, count = response["searchId"], response["resultCount"]

      if count == 0
        @page.command("DOM.discardSearchResults", searchId: search_id)
        return results
      end

      response = @page.command("DOM.getSearchResults", searchId: search_id, fromIndex: 0, toIndex: count)
      results = response["nodeIds"].map do |node_id|
        node = @page.command("DOM.describeNode", nodeId: node_id)["node"]
        next if node["nodeType"] != 1 # nodeType: 3, nodeName: "#text" for example
        node["nodeId"] = node_id
        node["selector"] = selector
        [nil, node] # FIXME: page_id
      end.compact

      Array(results)
    end

    def find_within(page_id, id, method, selector)
      command "find_within", page_id, id, method, selector
    end

    def all_text(page_id, id)
      command "all_text", page_id, id
    end

    def visible_text(page_id, node)
      begin
        resolved = @page.command("DOM.resolveNode", nodeId: node["nodeId"])
        object_id = resolved["object"]["objectId"]
      rescue BrowserError => e
        if e.message == "No node with given id found"
          raise ObsoleteNode.new(self, e.response)
        end

        raise
      end

      response = @page.command("Runtime.callFunctionOn", objectId: object_id, functionDeclaration: %Q(
        function () { return this.innerText }
      ))

      response["result"]["value"]
    end

    def delete_text(page_id, id)
      command "delete_text", page_id, id
    end

    def property(page_id, id, name)
      command "property", page_id, id, name.to_s
    end

    def attributes(page_id, id)
      command "attributes", page_id, id
    end

    def attribute(page_id, id, name)
      command "attribute", page_id, id, name.to_s
    end

    def value(page_id, id)
      command "value", page_id, id
    end

    def set(page_id, id, value)
      command "set", page_id, id, value
    end

    def select_file(page_id, id, value)
      command "select_file", page_id, id, value
    end

    def tag_name(page_id, id)
      command("tag_name", page_id, id).downcase
    end

    def visible?(page_id, node)
      response = @page.command("CSS.getComputedStyleForNode", nodeId: node["nodeId"])
      style = response["computedStyle"]
      display = style.find { |s| s["name"] == "display" }["value"]
      visibility = style.find { |s| s["name"] == "visibility" }["value"]
      opacity = style.find { |s| s["name"] == "opacity" }["value"]
      display != "none" && visibility != "hidden" && opacity != "0"
    end

    def disabled?(page_id, id)
      command "disabled", page_id, id
    end

    def click_coordinates(x, y)
      command "click_coordinates", x, y
    end

    # FIXME: *args
    def evaluate(expression, *args)
      # command "evaluate", script, *args
      result = @page.command("Runtime.evaluate", expression: expression)
      puts result
      result["result"]["value"]
    end

    # FIXME: *args
    def evaluate_async(expression, wait_time, *args)
      # command "evaluate_async", script, wait_time, *args
      @page.command("Runtime.evaluate", expression: expression)["result"]["value"]
    end

    # FIXME: *args
    def execute(expression, *args)
      @page.command("Runtime.evaluate", expression: expression)["result"]["value"]
    end

    def within_frame(handle)
      if handle.is_a?(Capybara::Node::Base)
        command "push_frame", [handle.native.page_id, handle.native.id]
      else
        command "push_frame", handle
      end

      yield
    ensure
      command "pop_frame"
    end

    def switch_to_frame(handle)
      case handle
      when Capybara::Node::Base
        command "push_frame", [handle.native.page_id, handle.native.id]
      when :parent
        command "pop_frame"
      when :top
        command "pop_frame", true
      end
    end

    def window_handle
      command "window_handle"
    end

    def window_handles
      command "window_handles"
    end

    def switch_to_window(handle)
      command "switch_to_window", handle
    end

    def open_new_window
      command "open_new_window"
    end

    def close_window(handle)
      command "close_window", handle
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

    def click(page_id, node, keys = [], offset = {})
      resolved = @page.command("DOM.resolveNode", nodeId: node["nodeId"])
      result = @page.command("Runtime.callFunctionOn", objectId: resolved["object"]["objectId"], functionDeclaration: %Q(
        function () {
          isInViewport = function(node) {
            rect = node.getBoundingClientRect();
            return rect.top >= 0 &&
                   rect.left >= 0 &&
                   rect.bottom <= window.innerHeight &&
                   rect.right <= window.innerWidth;
          }

          this.scrollIntoViewIfNeeded();

          if (!isInViewport(this)) {
            this.scrollIntoView({block: 'center', inline: 'center', behavior: 'instant'});
            return isInViewport(this);
          }

          return true;
        }
      ))["result"]

      raise MouseEventFailed.new(node, nil) unless result["value"]

      result = @page.command("DOM.getContentQuads", nodeId: node["nodeId"])
      raise "Node is either not visible or not an HTMLElement" if result["quads"].size == 0

      # FIXME: Case when a few quads returned
      quads = result["quads"].map do |quad|
        [{x: quad[0], y: quad[1]},
         {x: quad[2], y: quad[3]},
         {x: quad[4], y: quad[5]},
         {x: quad[6], y: quad[7]}]
      end

      x, y = quads[0].inject([0, 0]) { |b, p| [b[0] + p[:x], b[1] + p[:y]] }
      x /= 4
      y /= 4

      # command "click", page_id, node, keys, offset
      @page.command("Input.dispatchMouseEvent", type: "mouseMoved", x: x, y: y) # hover then click?
      @page.command("Input.dispatchMouseEvent", type: "mousePressed", button: "left", x: x, y: y, clickCount: 1)
      @page.command("Input.dispatchMouseEvent", type: "mouseReleased", button: "left", x: x, y: y, clickCount: 1)
    end

    def right_click(page_id, id, keys = [], offset = {})
      command "right_click", page_id, id, keys, offset
    end

    def double_click(page_id, id, keys = [], offset = {})
      command "double_click", page_id, id, keys, offset
    end

    def hover(page_id, node)
      result = @page.command("DOM.getContentQuads", nodeId: node["nodeId"])
      raise "Node is either not visible or not an HTMLElement" if result["quads"].size == 0

      # FIXME: Case when a few quad returned
      quads = result["quads"].map do |quad|
        [{x: quad[0], y: quad[1]},
         {x: quad[2], y: quad[3]},
         {x: quad[4], y: quad[5]},
         {x: quad[6], y: quad[7]}]
      end

      x, y = quads[0].inject([0, 0]) { |b, p| [b[0] + p[:x], b[1] + p[:y]] }
      x /= 4
      y /= 4

      @page.command("Input.dispatchMouseEvent", type: "mouseMoved", x: x, y: y)
      # command "hover", page_id, id
    end

    def drag(page_id, id, other_id)
      command "drag", page_id, id, other_id
    end

    def drag_by(page_id, id, x, y)
      command "drag_by", page_id, id, x, y
    end

    def select(page_id, id, value)
      command "select", page_id, id, value
    end

    def trigger(page_id, id, event)
      command "trigger", page_id, id, event.to_s
    end

    def reset
      @page.close if @page
      @page = Page.new(self, @logger)
    end

    def scroll_to(left, top)
      command "scroll_to", left, top
    end

    def render(path, _options = {})
      # check_render_options!(options)
      # options[:full] = !!options[:full]
      data = Base64.decode64(render_base64)
      File.open(path.to_s, "w") { |f| f.write(data) }
    end

    def render_base64(format = "png", _options = {})
      # check_render_options!(options)
      # options[:full] = !!options[:full]
      @page.command("Page.captureScreenshot", format: format)["data"]
    end

    def set_zoom_factor(zoom_factor)
      command "set_zoom_factor", zoom_factor
    end

    def set_paper_size(size)
      command "set_paper_size", size
    end

    def resize(width, height)
      @page.resize(width, height)
    end

    def send_keys(page_id, id, keys)
      command "send_keys", page_id, id, normalize_keys(keys)
    end

    def path(page_id, id)
      command "path", page_id, id
    end

    def network_traffic(type = nil)
    end

    def clear_network_traffic
      command("clear_network_traffic")
    end

    def set_proxy(ip, port, type, user, password)
      args = [ip, port, type]
      args << user if user
      args << password if password
      command("set_proxy", *args)
    end

    def equals(page_id, id, other_id)
      command("equals", page_id, id, other_id)
    end

    def get_headers
      command "get_headers"
    end

    def set_headers(headers)
      command "set_headers", headers
    end

    def add_headers(headers)
      command "add_headers", headers
    end

    def add_header(header, options = {})
      command "add_header", header, options
    end

    def response_headers
      command "response_headers"
    end

    def cookies
      Hash[command("cookies").map { |cookie| [cookie["name"], Cookie.new(cookie)] }]
    end

    def set_cookie(cookie)
      cookie[:expires] = cookie[:expires].to_i * 1000 if cookie[:expires]
      command "set_cookie", cookie
    end

    def remove_cookie(name)
      command "remove_cookie", name
    end

    def clear_cookies
      command "clear_cookies"
    end

    def cookies_enabled=(flag)
      command "cookies_enabled", !!flag
    end

    def set_http_auth(user, password)
      command "set_http_auth", user, password
    end

    def page_settings=(settings)
      command "set_page_settings", settings
    end

    def url_whitelist=(whitelist)
      command "set_url_whitelist", *whitelist
    end

    def url_blacklist=(blacklist)
      command "set_url_blacklist", *blacklist
    end

    def clear_memory_cache
      command "clear_memory_cache"
    end

    def go_back
      command "go_back"
    end

    def go_forward
      command "go_forward"
    end

    def refresh
      command "refresh"
    end

    def accept_confirm
      command "set_confirm_process", true
    end

    def dismiss_confirm
      command "set_confirm_process", false
    end

    def accept_prompt(response)
      command "set_prompt_response", response || false
    end

    def dismiss_prompt
      command "set_prompt_response", nil
    end

    def modal_message
      command "modal_message"
    end

    private

    def check_render_options!(options)
      return if !options[:full] || !options.key?(:selector)
      warn "Ignoring :selector in #render since :full => true was given at #{caller(1..1).first}"
      options.delete(:selector)
    end
  end
end

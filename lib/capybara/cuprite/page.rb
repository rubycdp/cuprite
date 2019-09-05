# frozen_string_literal: true

module Capybara::Cuprite
  module Page
    def set(node, value)
      object_id = command("DOM.resolveNode", nodeId: node.node_id).dig("object", "objectId")
      evaluate("_cuprite.set(arguments[0], arguments[1])", { "objectId" => object_id }, value)
    end

    def select(node, value)
      evaluate_on(node: node, expression: "_cuprite.select(this, #{value})")
    end

    def trigger(node, event)
      options = {}
      options.merge!(timeout: 0.1) if event.to_s == "click"
      evaluate_on(node: node, expression: %(_cuprite.trigger(this, "#{event}")), **options)
    end

    def hover(node)
      evaluate_on(node: node, expression: "_cuprite.scrollIntoViewport(this)")
      x, y = find_position(node)
      command("Input.dispatchMouseEvent", type: "mouseMoved", x: x, y: y)
    end

    def send_keys(node, keys)
      if !evaluate_on(node: node, expression: %(_cuprite.containsSelection(this)))
        before_click(node, "click")
        node.click(mode: :left, keys: keys)
      end

      keyboard.type(keys)
    end

    def find_modal(*)
      super
    rescue Ferrum::ModalNotFoundError => e
      raise Capybara::ModalNotFound, e.message
    end

    def before_click(node, name, keys = [], offset = {})
      evaluate_on(node: node, expression: "_cuprite.scrollIntoViewport(this)")
      x, y = find_position(node, offset[:x], offset[:y])
      evaluate_on(node: node, expression: "_cuprite.mouseEventTest(this, '#{name}', #{x}, #{y})")
      true
    rescue Ferrum::JavaScriptError => e
      raise MouseEventFailed.new(e.message) if e.class_name == "MouseEventFailed"
    end

    def switch_to_frame(handle)
      case handle
      when :parent
        @frame_stack.pop
      when :top
        @frame_stack = []
      else
        @frame_stack << handle
        inject_extensions
      end
    end

    private

    def prepare_page
      super

      intercept_request if !Array(@browser.url_whitelist).empty? ||
                           !Array(@browser.url_blacklist).empty?

      on_request_intercepted do |request, index, total|
        if @browser.url_blacklist && !@browser.url_blacklist.empty?
          if @browser.url_blacklist.any? { |r| request.match?(r) }
            request.abort and return
          else
            request.continue and return
          end
        elsif @browser.url_whitelist && !@browser.url_whitelist.empty?
          if @browser.url_whitelist.any? { |r| request.match?(r) }
            request.continue and return
          else
            request.abort and return
          end
        elsif index + 1 < total
          # There are other callbacks that may handle this request
          next
        else
          # If there are no callbacks then just continue
          request.continue
        end
      end
    end

    def get_content_quads(*args)
      super
    rescue Ferrum::BrowserError => e
      if e.message == "Could not compute content quads."
        raise MouseEventFailed.new("MouseEventFailed: click, none, 0, 0")
      end

      raise
    end
  end
end

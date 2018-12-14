# frozen_string_literal: true

require "forwardable"

module Capybara::Cuprite
  class Input

    extend Forwardable

    delegate page: :@targets

    def initialize(targets)
      @targets = targets
    end

    def click(target_id, node, keys = [], offset = {})
      x, y, modifiers = prepare_before_click(node, keys, offset)
      page.command("Input.dispatchMouseEvent", type: "mousePressed", modifiers: modifiers, button: "left", x: x, y: y, clickCount: 1)
      page.command("Input.dispatchMouseEvent", type: "mouseReleased", modifiers: modifiers, button: "left", x: x, y: y, clickCount: 1)
      sleep(0.05) # FIXME: we have to wait for network event and then signal to thread
    end

    def right_click(target_id, node, keys = [], offset = {})
      x, y, modifiers = prepare_before_click(node, keys, offset)
      page.command("Input.dispatchMouseEvent", type: "mousePressed", modifiers: modifiers, button: "right", x: x, y: y, clickCount: 1)
      page.command("Input.dispatchMouseEvent", type: "mouseReleased", modifiers: modifiers, button: "right", x: x, y: y, clickCount: 1)
    end

    def double_click(target_id, node, keys = [], offset = {})
      x, y, modifiers = prepare_before_click(node, keys, offset)
      page.command("Input.dispatchMouseEvent", type: "mousePressed", modifiers: modifiers, button: "left", x: x, y: y, clickCount: 2)
      page.command("Input.dispatchMouseEvent", type: "mouseReleased", modifiers: modifiers, button: "left", x: x, y: y, clickCount: 2)
    end

    def hover(target_id, node)
      x, y = calculate_quads(node)
      page.command("Input.dispatchMouseEvent", type: "mouseMoved", x: x, y: y)
    end

    def set(target_id, node, value)
      click(target_id, node)
      page.evaluate(node, "this.value = ''")
      value.each_char do |char|
        page.command("Input.insertText", text: char)
        # page.command("Input.dispatchKeyEvent", type: "keyDown", text: value, unmodifiedText: value)
        # page.command("Input.dispatchKeyEvent", type: "keyUp")
      end
    end

    def click_coordinates(x, y)
      page.command "click_coordinates", x, y
    end

    def drag(target_id, id, other_id)
      page.command "drag", target_id, id, other_id
    end

    def drag_by(target_id, id, x, y)
      page.command "drag_by", target_id, id, x, y
    end

    def select(_target_id, node, value)
      page.evaluate(node, "_cuprite.select(this, #{value})")
    end

    def trigger(target_id, id, event)
      page.command "trigger", target_id, id, event.to_s
    end

    def scroll_to(left, top)
      page.command "scroll_to", left, top
    end

    def send_keys(target_id, id, keys)
      page.command "send_keys", target_id, id, normalize_keys(keys)
    end

    private

    def prepare_before_click(node, keys, offset)
      value = page.evaluate(node, "_cuprite.scrollIntoViewport(this)")
      raise MouseEventFailed.new(node, nil) unless value

      x, y = calculate_quads(node, offset[:x], offset[:y])

      click_modifiers = { alt: 1, ctrl: 2, control: 2, meta: 4, command: 4, shift: 8 }
      modifiers = keys.map { |k| click_modifiers[k.to_sym] }.compact.reduce(0, :|)

      page.command("Input.dispatchMouseEvent", type: "mouseMoved", x: x, y: y)

      [x, y, modifiers]
    end

    def calculate_quads(node, offset_x = nil, offset_y = nil)
      quads = get_content_quads(node)
      offset_x, offset_y = offset_x.to_i, offset_y.to_i

      if offset_x > 0 || offset_y > 0
        point = quads.first
        [point[:x] + offset_x, point[:y] + offset_y]
      else
        x, y = quads.inject([0, 0]) do |memo, point|
          [memo[0] + point[:x],
           memo[1] + point[:y]]
        end
        [x / 4, y / 4]
      end
    end

    def get_content_quads(node)
      result = page.command("DOM.getContentQuads", nodeId: node["nodeId"])
      raise "Node is either not visible or not an HTMLElement" if result["quads"].size == 0

      # FIXME: Case when a few quads returned
      result["quads"].map do |quad|
        [{x: quad[0], y: quad[1]},
         {x: quad[2], y: quad[3]},
         {x: quad[4], y: quad[5]},
         {x: quad[6], y: quad[7]}]
      end.first
    end
  end
end

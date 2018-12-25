module Capybara::Cuprite
  class Browser
    module Input
      def click(node, keys = [], offset = {})
        x, y, modifiers = prepare_before_click(node, keys, offset)
        command("Input.dispatchMouseEvent", type: "mousePressed", modifiers: modifiers, button: "left", x: x, y: y, clickCount: 1)
        @wait = 0.05 # Potential wait because if network event is triggered then we have to wait until it's over.
        command("Input.dispatchMouseEvent", type: "mouseReleased", modifiers: modifiers, button: "left", x: x, y: y, clickCount: 1)
      end

      def click_coordinates(x, y)
        c("Input.dispatchMouseEvent", type: "mousePressed", button: "left", x: x, y: y, clickCount: 1)
        @wait = 0.05 # Potential wait because if network event is triggered then we have to wait until it's over.
        command("Input.dispatchMouseEvent", type: "mouseReleased", button: "left", x: x, y: y, clickCount: 1)
      end

      def right_click(node, keys = [], offset = {})
        x, y, modifiers = prepare_before_click(node, keys, offset)
        command("Input.dispatchMouseEvent", type: "mousePressed", modifiers: modifiers, button: "right", x: x, y: y, clickCount: 1)
        command("Input.dispatchMouseEvent", type: "mouseReleased", modifiers: modifiers, button: "right", x: x, y: y, clickCount: 1)
      end

      def double_click(node, keys = [], offset = {})
        x, y, modifiers = prepare_before_click(node, keys, offset)
        command("Input.dispatchMouseEvent", type: "mousePressed", modifiers: modifiers, button: "left", x: x, y: y, clickCount: 2)
        command("Input.dispatchMouseEvent", type: "mouseReleased", modifiers: modifiers, button: "left", x: x, y: y, clickCount: 2)
      end

      def hover(node)
        x, y = calculate_quads(node)
        command("Input.dispatchMouseEvent", type: "mouseMoved", x: x, y: y)
      end

      def set(node, value)
        click(node)
        evaluate(node, "this.value = ''")
        value.each_char do |char|
          command("Input.insertText", text: char)
          # command("Input.dispatchKeyEvent", type: "keyDown", text: value, unmodifiedText: value)
          # command("Input.dispatchKeyEvent", type: "keyUp")
        end
      end

      def drag(node, other_node)
        command "drag", node, other_node
      end

      def drag_by(node, x, y)
        command "drag_by", node, x, y
      end

      def select(node, value)
        evaluate(node, "_cuprite.select(this, #{value})")
      end

      def trigger(node, event)
        evaluate(node, %(_cuprite.trigger("#{event.to_s}", {}, this)))
      end

      def scroll_to(left, top)
        command "scroll_to", left, top
      end

      def send_keys(node, keys)
        command "send_keys", node, normalize_keys(keys)
      end

      private

      def prepare_before_click(node, keys, offset)
        value = evaluate(node, "_cuprite.scrollIntoViewport(this)")
        raise MouseEventFailed.new(node, nil) unless value

        x, y = calculate_quads(node, offset[:x], offset[:y])

        click_modifiers = { alt: 1, ctrl: 2, control: 2, meta: 4, command: 4, shift: 8 }
        modifiers = keys.map { |k| click_modifiers[k.to_sym] }.compact.reduce(0, :|)

        command("Input.dispatchMouseEvent", type: "mouseMoved", x: x, y: y)

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
        result = command("DOM.getContentQuads", nodeId: node["nodeId"])
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
end

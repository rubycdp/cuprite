module Capybara::Cuprite
  class Browser
    module Input
      def click(node, keys = [], offset = {})
        x, y, modifiers = prepare_before_click(__method__, node, keys, offset)
        command("Input.dispatchMouseEvent", type: "mousePressed", modifiers: modifiers, button: "left", x: x, y: y, clickCount: 1)
        @wait = 0.05 # Potential wait because if network event is triggered then we have to wait until it's over.
        command("Input.dispatchMouseEvent", type: "mouseReleased", modifiers: modifiers, button: "left", x: x, y: y, clickCount: 1)
      end

      def right_click(node, keys = [], offset = {})
        x, y, modifiers = prepare_before_click(__method__, node, keys, offset)
        command("Input.dispatchMouseEvent", type: "mousePressed", modifiers: modifiers, button: "right", x: x, y: y, clickCount: 1)
        command("Input.dispatchMouseEvent", type: "mouseReleased", modifiers: modifiers, button: "right", x: x, y: y, clickCount: 1)
      end

      def double_click(node, keys = [], offset = {})
        x, y, modifiers = prepare_before_click(__method__, node, keys, offset)
        command("Input.dispatchMouseEvent", type: "mousePressed", modifiers: modifiers, button: "left", x: x, y: y, clickCount: 2)
        command("Input.dispatchMouseEvent", type: "mouseReleased", modifiers: modifiers, button: "left", x: x, y: y, clickCount: 2)
      end

      def click_coordinates(x, y)
        command("Input.dispatchMouseEvent", type: "mousePressed", button: "left", x: x, y: y, clickCount: 1)
        @wait = 0.05 # Potential wait because if network event is triggered then we have to wait until it's over.
        command("Input.dispatchMouseEvent", type: "mouseReleased", button: "left", x: x, y: y, clickCount: 1)
      end

      def hover(node)
        evaluate_on(node: node, expr: "_cuprite.scrollIntoViewport(this)")
        x, y = calculate_quads(node)
        command("Input.dispatchMouseEvent", type: "mouseMoved", x: x, y: y)
      end

      def set(node, value)
        object_id = command("DOM.resolveNode", nodeId: node["nodeId"]).dig("object", "objectId")
        evaluate("_cuprite.set(arguments[0], arguments[1])", { "objectId" => object_id }, value)
      end

      def drag(node, other)
        raise NotImplementedError
      end

      def drag_by(node, x, y)
        raise NotImplementedError
      end

      def select(node, value)
        evaluate_on(node: node, expr: "_cuprite.select(this, #{value})")
      end

      def trigger(node, event)
        options = event.to_s == "click" ? { wait: 0.1 } : {}
        evaluate_on(node: node, expr: %(_cuprite.trigger(this, "#{event}")), **options)
      end

      def scroll_to(left, top)
        raise NotImplementedError
      end

      def send_keys(node, keys)
        click(node) if !evaluate_on(node: node, expr: %(_cuprite.containsSelection(this)))

        keys.first.each_char do |char|
          # Check puppeteer Input.js and USKeyboardLayout.js also send_keys and modifiers from poltergeist.
          if /\n/.match(char)
            command("Input.insertText", text: char)
            # command("Input.dispatchKeyEvent", type: "keyDown", code: "Enter", key: "Enter", text: "\r")
            # command("Input.dispatchKeyEvent", type: "keyUp", code: "Enter", key: "Enter")
          else
            command("Input.dispatchKeyEvent", type: "keyDown", text: char)
            command("Input.dispatchKeyEvent", type: "keyUp", text: char)
          end
        end
      end

      private

      def prepare_before_click(name, node, keys, offset)
        evaluate_on(node: node, expr: "_cuprite.scrollIntoViewport(this)")
        x, y = calculate_quads(node, offset[:x], offset[:y])
        evaluate_on(node: node, expr: "_cuprite.mouseEventTest(this, '#{name}', #{x}, #{y})")

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

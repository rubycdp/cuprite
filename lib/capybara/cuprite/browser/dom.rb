module Capybara::Cuprite
  class Browser
    module DOM
      def body
        response = command("DOM.getDocument", depth: 0)
        response = command("DOM.getOuterHTML", nodeId: response["root"]["nodeId"])
        response["outerHTML"]
      end

      def all_text(node)
        evaluate(node, "this.textContent")
      end

      def property(node, name)
        evaluate(node, %Q(this["#{name}"]))
      end

      def attributes(node)
        value = evaluate(node, "_cuprite.getAttributes(this)")
        JSON.parse(value)
      end

      def attribute(node, name)
        evaluate(node, %Q(_cuprite.getAttribute(this, "#{name}")))
      end

      def value(node)
        evaluate(node, "_cuprite.value(this)")
      end

      def visible?(node)
        evaluate(node, "_cuprite.isVisible(this)")
      end

      def disabled?(node)
        evaluate(node, "_cuprite.isDisabled(this)")
      end

      def path(node)
        evaluate(node, "_cuprite.path(this)")
      end
    end
  end
end

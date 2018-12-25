module Capybara::Cuprite
  class Browser
    module DOM
      def current_url
        evaluate_in(@execution_context_id, "location.href")
      end

      def title
        evaluate("document.title")
      end

      def body
        response = command("DOM.getDocument", depth: 0)
        response = command("DOM.getOuterHTML", nodeId: response["root"]["nodeId"])
        response["outerHTML"]
      end

      def all_text(node)
        evaluate_on(node: node, expr: "this.textContent")
      end

      def property(node, name)
        evaluate_on(node: node, expr: %Q(this["#{name}"]))
      end

      def attributes(node)
        value = evaluate_on(node: node, expr: "_cuprite.getAttributes(this)")
        JSON.parse(value)
      end

      def attribute(node, name)
        evaluate_on(node: node, expr: %Q(_cuprite.getAttribute(this, "#{name}")))
      end

      def value(node)
        evaluate_on(node: node, expr: "_cuprite.value(this)")
      end

      def visible?(node)
        evaluate_on(node: node, expr: "_cuprite.isVisible(this)")
      end

      def disabled?(node)
        evaluate_on(node: node, expr: "_cuprite.isDisabled(this)")
      end

      def path(node)
        evaluate_on(node: node, expr: "_cuprite.path(this)")
      end
    end
  end
end

# frozen_string_literal: true

module Capybara
  module Cuprite
    module Finder
      module_function

      def find(browser, method, selector, within = nil, **hints)
        # Capybara appends its text-match hint as `(expr)[...]`, but with `exact_text: true` the hint
        # is empty and the result `(expr)[]` is invalid XPath. An empty predicate is never valid, so
        # dropping it can't change a valid selector. Remove once teamcapybara/capybara#2860 is released.
        selector = selector.delete_suffix("[]") if method == :xpath
        styles = hints[:styles]
        hints = {
          visible: hints.fetch(:uses_visibility, false),
          texts: hints.fetch(:texts, []),
          styles: (styles.keys.map(&:to_s) if styles.is_a?(Hash)),
          position: hints.fetch(:position, false)
        }

        answers = browser.evaluate("_cuprite.findWithHints(...arguments)", *[method, selector, hints, within].compact)
        hidden = answers["hidden"]&.to_set
        style = answers["style"]
        position = answers["position"]
        answers["nodes"].each_with_index.map do |node, index|
          cache = {}
          cache[:visible] = !hidden.include?(index) if hidden
          cache[:style] = style.transform_values { |values| values[index] } if style
          cache[:position] = position[index] if position
          [node, cache]
        end
      rescue Ferrum::JavaScriptError => e
        raise InvalidSelector.new(e.response, method, selector) if e.class_name == "InvalidSelector"

        raise
      end
    end
  end
end

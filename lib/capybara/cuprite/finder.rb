# frozen_string_literal: true

module Capybara
  module Cuprite
    module Finder
      module_function

      def find(browser, method, selector, within = nil)
        # Capybara appends its text-match hint as `(expr)[...]`, but with `exact_text: true` the hint
        # is empty and the result `(expr)[]` is invalid XPath. An empty predicate is never valid, so
        # dropping it can't change a valid selector. Remove once teamcapybara/capybara#2860 is released.
        selector = selector.delete_suffix("[]") if method == :xpath
        nodes = browser.evaluate("_cuprite.find(...arguments)", *[method, selector, within].compact)
        nodes.select(&:node?)
      rescue Ferrum::JavaScriptError => e
        raise InvalidSelector.new(e.response, method, selector) if e.class_name == "InvalidSelector"

        raise
      end
    end
  end
end

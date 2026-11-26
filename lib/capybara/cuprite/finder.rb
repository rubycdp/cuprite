# frozen_string_literal: true

require "capybara/cuprite/finder/hints"

module Capybara
  module Cuprite
    # Looks up the elements for {Driver} and {Node}.
    # @api private
    module Finder
      module_function

      # Finds the nodes matching a selector and answers Capybara's finder hints in the same call.
      #
      # @param frame [Ferrum::Frame] the frame to search in
      # @param method [Symbol] `:css` or `:xpath`
      # @param selector [String]
      # @param within [Ferrum::Node, nil] the node to search in, the document by default
      # @param hints [Hash] the hints Capybara passes to `find_css` and `find_xpath`
      # @return [Array<Array(Ferrum::Node, Hash)>] each node with its initial cache
      # @raise [InvalidSelector]
      def find(frame, method, selector, within = nil, **hints)
        # Capybara appends its text-match hint as `(expr)[...]`, but with `exact_text: true` the hint
        # is empty and the result `(expr)[]` is invalid XPath. An empty predicate is never valid, so
        # dropping it can't change a valid selector. Remove once teamcapybara/capybara#2860 is released.
        selector = selector.delete_suffix("[]") if method == :xpath
        hints = Hints.new(**hints)
        nodes, *answers = frame.evaluate("_cuprite.findWithHints(method, selector, within, hints)",
                                         method: method, selector: selector, within: within, hints: hints.to_h)
        nodes.zip(hints.caches(nodes.size, *answers))
      rescue Ferrum::JavaScriptError => e
        raise InvalidSelector.new(e.response, method, selector) if e.class_name == "InvalidSelector"

        raise
      end
    end
  end
end

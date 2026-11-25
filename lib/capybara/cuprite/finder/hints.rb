# frozen_string_literal: true

module Capybara
  module Cuprite
    module Finder
      # Capybara's finder hints for one query: what the browser is asked to answer along with
      # the nodes it finds, and the initial cache of each node built from that answer.
      # @api private
      class Hints
        # @param uses_visibility [Boolean] whether the query filters on visibility
        # @param texts [Array<String>] the fragments every matching node's text has to contain
        # @param styles [Hash, nil] the computed styles the query filters on
        # @param position [Boolean] whether the query filters on the position of the nodes
        def initialize(uses_visibility: false, texts: [], styles: nil, position: false, **)
          @visible = uses_visibility
          @texts = texts
          @styles = styles.keys.map(&:to_s) if styles.is_a?(Hash)
          @position = position
        end

        # @return [Hash] the hints as `_cuprite.findWithHints` takes them
        def to_h
          { visible: @visible, texts: @texts, styles: @styles, position: @position }
        end

        # Builds the initial cache of each node from the browser's answer, which holds one
        # list per hint instead of one cache per node, as Chrome serializes that faster.
        #
        # @param count [Integer] the number of nodes found
        # @param hidden [Array<Integer>, nil] the indexes of the hidden nodes
        # @param style [Hash{String => Array<String>}, nil] each style's value for every node
        # @param position [Array<Hash>, nil] the bounding rectangle of every node
        # @param texts [Array<Array>, nil] all text and visible text of every node
        # @return [Array<Hash>] one cache per node, in the order of the nodes
        def caches(count, hidden, style, position, texts)
          hidden = hidden&.to_set
          all_texts, visible_texts = texts

          Array.new(count) do |index|
            cache = {}
            cache[:visible] = !hidden.include?(index) if hidden
            cache[:style] = style.transform_values { |values| values[index] } if style
            cache[:position] = position[index] if position
            cache.merge!(all_text: all_texts[index], visible_text: visible_texts[index]) if texts
            cache
          end
        end
      end
    end
  end
end

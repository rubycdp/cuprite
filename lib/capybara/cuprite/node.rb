# frozen_string_literal: true

require "capybara/cuprite/finder"
require "capybara/cuprite/node/extensions"
require "capybara/cuprite/node/typing"

module Capybara
  module Cuprite
    # An element found by the {Driver}, which Capybara wraps in `Capybara::Node::Element`.
    class Node < Capybara::Driver::Node
      # @return [Ferrum::Node] the Ferrum node, for what Capybara doesn't cover
      attr_reader :node

      include Extensions
      include Typing

      # Capybara's names of modifier keys mapped to Ferrum's.
      # @api private
      DRAG_MODIFIER_ALIASES = { control: :ctrl, command: :meta, cmd: :meta }.freeze
      # The script that drags with HTML5 drag and drop events.
      # @api private
      DRAG_HTML5_JS = File.read(File.expand_path("javascripts/drag.js", __dir__))
      # @param driver [Driver]
      # @param node [Ferrum::Node]
      # @param initial_cache [Hash] what the finder already knows about the element, see Capybara's finder hints
      def initialize(driver, node, initial_cache = {})
        super(driver, self, initial_cache)
        @node = node
      end

      # @param selector [String]
      # @param hints [Hash] Capybara's finder hints
      # @return [Array<Node>] the descendants matching the XPath
      # @raise [InvalidSelector]
      # @raise [ObsoleteNode] when the element is no longer in the DOM
      def find_xpath(selector, **hints)
        find(:xpath, selector, **hints)
      end

      # @param selector [String]
      # @param hints [Hash] Capybara's finder hints
      # @return [Array<Node>] the descendants matching the CSS selector
      # @raise [InvalidSelector]
      # @raise [ObsoleteNode] when the element is no longer in the DOM
      def find_css(selector, **hints)
        find(:css, selector, **hints)
      end

      # A text in the initial cache comes only with a node that can't match its query's text, which
      # Capybara reads to filter it out and to describe the failure, and never hands to the caller.
      #
      # @return [String] all the text of the element, visible or not, with whitespace normalized
      def all_text
        filter_text(initial_cache.fetch(:all_text) { command { node.text } })
      end

      # @return [String] the text of the element a user can see
      # @raise [ObsoleteNode] when the element is no longer in the DOM
      def visible_text
        text = initial_cache.fetch(:visible_text) { command(:visibleText) }
        text.to_s
            .gsub(/\A[[:space:]&&[^\u00a0]]+/, "")
            .gsub(/[[:space:]&&[^\u00a0]]+\z/, "")
            .gsub(/\n+/, "\n")
            .tr("\u00a0", " ")
      end

      # Reads a property of the element, or the attribute when the property isn't a scalar. For `src` of an image
      # and `href` of a link it's the resolved property, if the attribute is present.
      #
      # @param name [String, Symbol]
      # @return [String, Numeric, Boolean, nil]
      def [](name)
        # Although the attribute matters, the property is consistent. Return that in
        # preference to the attribute for links and images.
        if (tag_name == "img" && name == "src") ||
           (tag_name == "a" && name == "href")
          # if attribute exists get the property
          return command(:getAttribute, name) && command { node.property(name) }
        end

        case (value = command { node.property(name) })
        when String, Numeric, true, false then value
        else command(:getAttribute, name)
        end
      end

      # @return [String, Array<String>, nil] the value of a form field, every selected one for a multiple select
      # @raise [ObsoleteNode] when the element is no longer in the DOM
      def value
        command(:value)
      end

      # Reads the computed styles of the node. The ones a `:style` filter cached aren't used, they may be out of date.
      #
      # @param styles [Array<String>] the CSS property names
      # @return [Hash{String => String}] the computed value of each property
      def style(styles)
        command { node.evaluate("_cuprite.styles([this], names)", names: styles) }.transform_values(&:first)
      end

      # Sets the value of a form field. Text inputs and textareas are typed with real key presses.
      #
      # @param value [String, Array<String>, Boolean, Date, Time] the value to set
      # @param options [Hash] Capybara's `fill_options`, the defaults come from `Capybara.default_set_options`. Other
      #   options are ignored with a warning, `rapid:` and `clear:` silently on fields other than text ones.
      # @option options [Boolean, nil] :rapid `true` types the first 4 and last 3 characters and sets the middle from
      #   JS, `false` types every character, `nil` does it for values over 30 characters
      # @option options [nil, :none, :backspace, Array] :clear `nil` replaces the value, `:none` appends to it,
      #   `:backspace` deletes it with Backspace first, an Array of keys is pressed before typing
      # @return [void]
      # @raise [ArgumentError] for an unknown `clear:` value, or an Array on a field without `multiple`
      def set(value, options = {}) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize
        warn_unsupported(options)
        raise ArgumentError, MULTIPLE_ERROR if value.is_a?(Array) && !multiple?

        if tag_name == "input"
          case self[:type]
          when *TYPED_INPUTS
            set_text(value.to_s, **options)
          when "radio"
            click
          when "checkbox"
            click if value != checked?
          when "file"
            files = value.respond_to?(:to_ary) ? value.to_ary.map(&:to_s) : value.to_s
            command { node.select_file(files) }
          when "color"
            node.evaluate("this.setAttribute('value', value)", value: value)
            node.evaluate("this.dispatchEvent(new InputEvent('input'))")
            node.evaluate("this.dispatchEvent(new Event('change', { bubbles: true }))")
          when "date"
            value = value.to_date.iso8601 if !value.is_a?(String) && value.respond_to?(:to_date)
            command(:set, value.to_s)
          when "time"
            value = value.to_time.strftime("%H:%M") if !value.is_a?(String) && value.respond_to?(:to_time)
            command(:set, value.to_s)
          when "month"
            value = value.to_date.strftime("%Y-%m") if !value.is_a?(String) && value.respond_to?(:to_date)
            command(:set, value.to_s)
          when "week"
            value = value.to_date.strftime("%G-W%V") if !value.is_a?(String) && value.respond_to?(:to_date)
            command(:set, value.to_s)
          when "datetime-local"
            value = value.to_time.strftime("%Y-%m-%dT%H:%M") if !value.is_a?(String) && value.respond_to?(:to_time)
            command(:set, value.to_s)
          else
            command(:set, value.to_s)
          end
        elsif tag_name == "textarea"
          set_text(value.to_s, **options)
        elsif self[:isContentEditable]
          command(:deleteText)
          click.type(value.to_s)
        end
      end

      # Selects the option element.
      #
      # @return [void]
      # @raise [ObsoleteNode] when the element is no longer in the DOM
      def select_option
        command(:select, true)
      end

      # Unselects the option element.
      #
      # @return [void]
      # @raise [Capybara::UnselectNotAllowed] for an option of a single select
      # @raise [ObsoleteNode] when the element is no longer in the DOM
      def unselect_option
        command(:select, false) ||
          raise(Capybara::UnselectNotAllowed, "Cannot unselect option from single select box.")
      end

      # @return [String] the lowercase tag name, `"ShadowRoot"` for a shadow root
      def tag_name
        @tag_name ||= node.description["shadowRootType"] ? "ShadowRoot" : node.description["nodeName"].downcase
      end

      # @return [Boolean]
      # @raise [ObsoleteNode] when the element is no longer in the DOM
      def visible?
        command(:isVisible)
      end

      # @return [Boolean]
      def checked?
        self[:checked]
      end

      # @return [Boolean]
      def selected?
        !!self[:selected]
      end

      # @return [Boolean] whether the element is disabled, itself or by a disabled fieldset or optgroup
      # @raise [ObsoleteNode] when the element is no longer in the DOM
      def disabled?
        command(:isDisabled)
      end

      # Scrolls the element into view and clicks it with the mouse.
      #
      # @param keys [Array<Symbol>] modifier keys held during the click
      # @param options [Hash]
      # @option options [Integer] :x offset from the position given by `:offset`, along with `:y`
      # @option options [Integer] :y offset from the position given by `:offset`, along with `:x`
      # @option options [:top, :center] :offset what `:x` and `:y` are relative to, the top left by default
      # @option options [Numeric] :delay seconds between pressing and releasing the button
      # @return [void]
      # @raise [MouseEventFailed] when another element would receive the click
      # @raise [ObsoleteNode] when the element is no longer in the DOM
      def click(keys = [], **options)
        prepare_and_click(__method__, keys, options)
      end

      # Clicks the element with the right mouse button, see {#click}.
      #
      # @param keys [Array<Symbol>] modifier keys held during the click
      # @param options [Hash] the options of {#click}
      # @return [void]
      # @raise [MouseEventFailed] when another element would receive the click
      # @raise [ObsoleteNode] when the element is no longer in the DOM
      def right_click(keys = [], **options)
        prepare_and_click(__method__, keys, options, button: :right)
      end

      # Double-clicks the element, see {#click}.
      #
      # @param keys [Array<Symbol>] modifier keys held during the clicks
      # @param options [Hash] the options of {#click}
      # @return [void]
      # @raise [MouseEventFailed] when another element would receive the click
      # @raise [ObsoleteNode] when the element is no longer in the DOM
      def double_click(keys = [], **options)
        prepare_and_click(__method__, keys, options, count: 2)
      end

      # Scrolls the element into view and moves the mouse over it.
      #
      # @return [void]
      # @raise [ObsoleteNode] when the element is no longer in the DOM
      def hover
        command do
          js(:scrollIntoViewport)
          x, y = pinpoint
          driver.current_page.command("Input.dispatchMouseEvent", type: "mouseMoved", x: x, y: y)
        end
      end

      # Drags the element onto another one, with HTML5 drag and drop events when the page uses them.
      #
      # @param other [Node]
      # @param options [Hash]
      # @option options [Integer] :x drop offset, along with `:y`
      # @option options [Integer] :y drop offset, along with `:x`
      # @option options [:top, :center] :offset what the drop offset is relative to, `:center` with `w3c_click_offset`,
      #   `:top` otherwise
      # @option options [Numeric] :delay seconds to wait after pressing the button
      # @option options [Integer] :steps mouse moves to reach the target, `1` by default
      # @option options [Boolean] :scroll scroll the elements into view, `true` by default
      # @option options [Boolean, nil] :html5 force or skip HTML5 drag and drop, detected by default
      # @option options [Array<Symbol>] :drop_modifiers modifier keys held while dropping
      # @return [void]
      # @raise [ArgumentError] when only one of `:x` and `:y` is given
      # @raise [ObsoleteNode] when the element is no longer in the DOM
      def drag_to(other, **options)
        raise ArgumentError, "You must specify both x: and y: for a drop offset" if options[:x].nil? ^ options[:y].nil?

        options[:steps] ||= 1
        options[:scroll] = true unless options.key?(:scroll)
        options[:drop_offset] = drop_offset(*options.values_at(:x, :y, :offset))
        modifiers = Array(options[:drop_modifiers]).map { |m| DRAG_MODIFIER_ALIASES.fetch(m.to_sym, m.to_sym) }

        command { drag(other.node, modifiers, options) }
      end

      # Drops files or strings onto the element.
      #
      # @param args [Array<String, Pathname>, Array<Hash{String => String}>] file paths, or MIME types mapped to data
      # @return [void]
      # @raise [ObsoleteNode] when the element is no longer in the DOM
      def drop(*args)
        command do
          if args[0].is_a?(String)
            driver.current_frame.execute("_cuprite.attachDropInput()")
            driver.current_frame.at_css("#_cuprite_drop_file").select_file(args)
            js(:dropFile)
          else
            strings = args.flat_map { |arg| arg.map { |type, data| { "type" => type, "data" => data } } }
            node.evaluate("_cuprite.dropString(strings, this)", strings: strings)
          end
        end
      end

      # Dispatches a DOM event on the element without moving the mouse. A `click` watches for the navigation it may
      # start like a real click, for Ferrum's `FERRUM_NAVIGATION_WAIT` seconds.
      #
      # @param event [String, Symbol]
      # @return [void]
      # @raise [ObsoleteNode] when the element is no longer in the DOM
      def trigger(event)
        command do
          wait = Ferrum::Page::NAVIGATION_WAIT
          next js(:trigger, event.to_s) unless event.to_s == "click" && wait.positive?

          driver.current_page.await_navigation!(watch: wait) { js(:trigger, "click") }
        end
      end

      # Scrolls an element into view inside this one, or this one to a location or position.
      #
      # @param element [Node, nil] the element to scroll into view
      # @param location [:top, :bottom, :center, nil]
      # @param position [Array(Numeric, Numeric), nil] the coordinates to scroll to
      # @return [self]
      # @raise [ArgumentError] for an unknown location with an element
      def scroll_to(element, location, position = nil)
        if element.is_a?(Node)
          scroll_element_to_location(element, location)
        elsif location.is_a?(Symbol)
          scroll_to_location(location)
        else
          scroll_to_coords(*position)
        end
        self
      end

      # @param x [Numeric]
      # @param y [Numeric]
      # @return [void]
      def scroll_by(x, y)
        node.evaluate("this.scrollBy(x, y)", x: x, y: y)
      end

      # @param other [Capybara::Node::Element, Node]
      # @return [Boolean] whether both are the same DOM element
      def ==(other)
        node == other.native.node
      end

      # Focuses the element, unless it already has focus, and types the keys, at the end of the value of a field.
      #
      # @param keys [Array<String, Symbol, Array>] text, key names and Arrays of keys pressed together
      # @return [void]
      # @raise [ObsoleteNode] when the element is no longer in the DOM
      def send_keys(*keys)
        keys = keys.reject { |key| key.nil? || key == "" }
        return if keys.empty?

        command do
          keyboard = driver.current_page.keyboard
          keyboard.type(:end) if js(:focusForTyping)
          keyboard.type(keys)
        end
      end

      # @return [String] an XPath that locates the element
      # @raise [ObsoleteNode] when the element is no longer in the DOM
      def path
        command(:path)
      end

      # @return [Boolean] whether the element is out of the viewport or covered by another one
      # @raise [ObsoleteNode] when the element is no longer in the DOM
      def obscured?
        command(:isObscured)
      end

      # @return [Node, nil] the open shadow root of the element
      def shadow_root
        root = driver.current_frame.evaluate("node.shadowRoot", node: node)
        root && self.class.new(driver, root)
      end

      # @return [Hash{String => Numeric}] the bounding rectangle: `x`, `y`, `width`, `height`, `top`, `right`, `bottom`,
      #   `left`
      def rect
        node.evaluate("this.getBoundingClientRect().toJSON()")
      end

      # @return [String]
      def inspect
        %(#<#{self.class} @node=#{@node.inspect}>)
      end

      private

      def find(method, selector, **hints)
        command { Finder.find(driver.current_frame, method, selector, node, **hints) }.map do |native, cache|
          self.class.new(driver, native, cache)
        end
      end

      def command(function = nil, *args)
        raise ObsoleteNode.new(self, nil) unless node.evaluate("this.isConnected")

        check_modals { block_given? ? yield : js(function, *args) }
      rescue Ferrum::NodeNotFoundError => e
        raise ObsoleteNode.new(self, e.response)
      end

      def prepare_and_click(name, keys, options, **click)
        delay = options[:delay].to_i
        x, y = options.values_at(:x, :y)
        offset = x && y ? { x: x, y: y, position: options[:offset] || :top } : {}
        command { before_click(name, offset) }
        check_modals { node.click(modifiers: keys, offset: offset, delay: delay, **click) }
      end

      def check_modals(&)
        driver.window.check_modals(&)
      end

      def js(function, *args)
        node.evaluate("_cuprite.#{function}(this, ...arguments)", *args)
      end

      def before_click(name, offset = {})
        js(:scrollIntoViewport)

        # If offset is given it may go outside of the element and likely error
        # will be raised that we detected another element at this position.
        return if offset.any?

        x, y = pinpoint
        js(:mouseEventTest, name.to_s, x, y)
      rescue Ferrum::JavaScriptError => e
        raise MouseEventFailed, e.message if e.class_name == "MouseEventFailed"
        raise ObsoleteNode.new(self, e.response) if e.class_name == "ObsoleteNode"

        raise
      end

      def pinpoint(**options)
        node.pinpoint(**options)
      rescue Ferrum::BrowserError => e
        raise MouseEventFailed, "MouseEventFailed: click, none, 0, 0" if e.message == "Could not compute content quads."

        raise
      end

      def drag(other, modifiers, options)
        page = driver.current_page
        delay, scroll, html5, drop_offset = options.values_at(:delay, :scroll, :html5, :drop_offset)
        driver.current_frame.execute("_cuprite.dragMousedownTracker()")

        node.scroll if scroll
        x1, y1 = node.pinpoint

        page.mouse.move(x: x1, y: y1)
        page.mouse.down
        sleep delay if delay

        html5 = !js(:legacyDragCheck) if html5.nil?

        if html5
          keys = modifiers.map(&:to_s)
          driver.evaluate_async_script(DRAG_HTML5_JS, node, other, (delay || 0.05) * 1000, keys, drop_offset)
          page.mouse.up
        else
          other.scroll if scroll
          x2, y2 = other.pinpoint(**drop_offset.to_h)

          page.keyboard.hold(*modifiers) { page.mouse.move(x: x2, y: y2, steps: options[:steps]).up }
        end
      end

      def drop_offset(x, y, position)
        return unless x

        position ||= driver.session_options.w3c_click_offset ? :center : :top
        { x: x, y: y, position: position.to_sym }
      end

      def filter_text(text)
        text.gsub(/[\u200b\u200e\u200f]/, "")
            .gsub(/[\ \n\f\t\v\u2028\u2029]+/, " ")
            .gsub(/\A[[:space:]&&[^\u00a0]]+/, "")
            .gsub(/[[:space:]&&[^\u00a0]]+\z/, "")
            .tr("\u00a0", " ")
      end

      def scroll_element_to_location(element, location)
        scroll_opts = case location
                      when :top
                        "true"
                      when :bottom
                        "false"
                      when :center
                        "{behavior: 'instant', block: 'center'}"
                      else
                        raise ArgumentError, "Invalid scroll_to location: #{location}"
                      end
        element.node.evaluate("await this.scrollIntoView(#{scroll_opts})")
      end

      def scroll_to_location(location)
        height = { top: "0",
                   bottom: "this.scrollHeight",
                   center: "(this.scrollHeight - this.clientHeight) / 2" }

        node.evaluate("await this.scrollTo(0, #{height[location]})")
      end

      def scroll_to_coords(x, y)
        node.evaluate("this.scrollTo(x, y)", x: x, y: y)
      end
    end
  end
end

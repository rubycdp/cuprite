# frozen_string_literal: true

require "capybara/cuprite/finder"
require "capybara/cuprite/node/extensions"

module Capybara
  module Cuprite
    class Node < Capybara::Driver::Node
      attr_reader :node

      include Extensions

      DRAG_MODIFIER_ALIASES = { control: :ctrl, command: :meta, cmd: :meta }.freeze
      DRAG_HTML5_JS = File.read(File.expand_path("javascripts/drag.js", __dir__))
      TRIGGER_CLICK_WAIT = ENV.fetch("CUPRITE_TRIGGER_CLICK_WAIT", 0.1).to_f

      def initialize(driver, node)
        super(driver, self)
        @node = node
      end

      def find_xpath(selector)
        find(:xpath, selector)
      end

      def find_css(selector)
        find(:css, selector)
      end

      def all_text
        filter_text(command { node.text })
      end

      def visible_text
        command(:visibleText).to_s
                             .gsub(/\A[[:space:]&&[^\u00a0]]+/, "")
                             .gsub(/[[:space:]&&[^\u00a0]]+\z/, "")
                             .gsub(/\n+/, "\n")
                             .tr("\u00a0", " ")
      end

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

      def value
        command(:value)
      end

      def set(value, options = {}) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize
        warn "Options passed to Node#set but Cuprite doesn't currently support any - ignoring" unless options.empty?

        if tag_name == "input"
          case self[:type]
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
          command(:set, value.to_s)
        elsif self[:isContentEditable]
          command(:deleteText)
          click.type(value.to_s)
        end
      end

      def select_option
        command(:select, true)
      end

      def unselect_option
        command(:select, false) ||
          raise(Capybara::UnselectNotAllowed, "Cannot unselect option from single select box.")
      end

      def tag_name
        @tag_name ||= node.description["shadowRootType"] ? "ShadowRoot" : node.description["nodeName"].downcase
      end

      def visible?
        command(:isVisible)
      end

      def checked?
        self[:checked]
      end

      def selected?
        !!self[:selected]
      end

      def disabled?
        command(:isDisabled)
      end

      def click(keys = [], **options)
        prepare_and_click(:left, __method__, keys, options)
      end

      def right_click(keys = [], **options)
        prepare_and_click(:right, __method__, keys, options)
      end

      def double_click(keys = [], **options)
        prepare_and_click(:double, __method__, keys, options)
      end

      def hover
        command do
          js(:scrollIntoViewport)
          x, y = find_position
          driver.browser.page.command("Input.dispatchMouseEvent", type: "mouseMoved", x: x, y: y)
        end
      end

      def drag_to(other, **options)
        raise ArgumentError, "You must specify both x: and y: for a drop offset" if options[:x].nil? ^ options[:y].nil?

        options[:steps] ||= 1
        options[:scroll] = true unless options.key?(:scroll)
        options[:drop_offset] = drop_offset(*options.values_at(:x, :y, :offset))
        modifiers = Array(options[:drop_modifiers]).map { |m| DRAG_MODIFIER_ALIASES.fetch(m.to_sym, m.to_sym) }

        command { drag(other.node, modifiers, options) }
      end

      def drop(*args)
        command do
          if args[0].is_a?(String)
            driver.browser.execute("_cuprite.attachDropInput()")
            driver.browser.at_css("#_cuprite_drop_file").select_file(args)
            js(:dropFile)
          else
            strings = args.flat_map { |arg| arg.map { |type, data| { "type" => type, "data" => data } } }
            node.evaluate("_cuprite.dropString(strings, this)", strings: strings)
          end
        end
      end

      def trigger(event)
        command do
          next js(:trigger, event.to_s) unless event.to_s == "click" && TRIGGER_CLICK_WAIT.positive?

          driver.browser.wait_for_navigation!(TRIGGER_CLICK_WAIT) { js(:trigger, "click") }
        end
      end

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

      def scroll_by(x, y)
        node.evaluate("this.scrollBy(x, y)", x: x, y: y)
      end

      def ==(other)
        node == other.native.node
      end

      def send_keys(*keys)
        keys = keys.reject { |key| key.nil? || key == "" }
        return if keys.empty?

        command do
          unless node.evaluate("_cuprite.containsSelection(this) || _cuprite.hasFocus(this)")
            before_click("click")
            node.click(mode: :left, keys: keys)
          end

          driver.browser.keyboard.type(keys)
        end
      end

      def path
        command(:path)
      end

      def obscured?
        command(:isObscured)
      end

      def shadow_root
        root = driver.browser.evaluate("node.shadowRoot", node: node)
        root && self.class.new(driver, root)
      end

      def rect
        node.evaluate("this.getBoundingClientRect().toJSON()")
      end

      def inspect
        %(#<#{self.class} @node=#{@node.inspect}>)
      end

      private

      def find(method, selector)
        command { Finder.find(driver.browser, method, selector, node) }.map do |node|
          self.class.new(driver, node)
        end
      end

      def command(function = nil, *args)
        raise ObsoleteNode.new(self, nil) unless node.evaluate("this.isConnected")

        block_given? ? yield : js(function, *args)
      rescue Ferrum::NodeNotFoundError => e
        raise ObsoleteNode.new(self, e.response)
      end

      def prepare_and_click(mode, name, keys, options)
        delay = options[:delay].to_i
        x, y = options.values_at(:x, :y)
        offset = { x: x, y: y, position: options[:offset] || :top }
        command { before_click(name, offset) }
        node.click(mode: mode, keys: keys, offset: offset, delay: delay)
      end

      def js(function, *args)
        node.evaluate("_cuprite.#{function}(this, ...arguments)", *args)
      end

      def before_click(name, offset = {})
        js(:scrollIntoViewport)

        # If offset is given it may go outside of the element and likely error
        # will be raised that we detected another element at this position.
        return if offset[:x] || offset[:y]

        x, y = find_position(**offset)
        js(:mouseEventTest, name.to_s, x, y)
      rescue Ferrum::JavaScriptError => e
        raise MouseEventFailed, e.message if e.class_name == "MouseEventFailed"

        raise
      end

      def find_position(**options)
        node.find_position(**options)
      rescue Ferrum::BrowserError => e
        raise MouseEventFailed, "MouseEventFailed: click, none, 0, 0" if e.message == "Could not compute content quads."

        raise
      end

      def drag(other, modifiers, options)
        browser = driver.browser
        delay, scroll, html5, drop_offset = options.values_at(:delay, :scroll, :html5, :drop_offset)
        browser.execute("_cuprite.dragMousedownTracker()")

        node.scroll_into_view if scroll
        x1, y1 = node.find_position

        browser.mouse.move(x: x1, y: y1)
        browser.mouse.down
        sleep delay if delay

        html5 = !js(:legacyDragCheck) if html5.nil?

        if html5
          keys = modifiers.map(&:to_s)
          driver.evaluate_async_script(DRAG_HTML5_JS, node, other, (delay || 0.05) * 1000, keys, drop_offset)
          browser.mouse.up
        else
          other.scroll_into_view if scroll
          x2, y2 = other.find_position(**drop_offset.to_h)

          browser.keyboard.hold(*modifiers) { browser.mouse.move(x: x2, y: y2, steps: options[:steps]).up }
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
        element.node.evaluate("this.scrollIntoView(#{scroll_opts})")
      end

      def scroll_to_location(location)
        height = { top: "0",
                   bottom: "this.scrollHeight",
                   center: "(this.scrollHeight - this.clientHeight) / 2" }

        node.evaluate("this.scrollTo(0, #{height[location]})")
      end

      def scroll_to_coords(x, y)
        node.evaluate("this.scrollTo(x, y)", x: x, y: y)
      end
    end
  end
end

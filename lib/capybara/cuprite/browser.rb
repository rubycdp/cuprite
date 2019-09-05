# frozen_string_literal: true

require "forwardable"

module Capybara::Cuprite
  class Browser < Ferrum::Browser
    extend Forwardable

    delegate %i[find_or_create_page] => :targets
    delegate %i[send_keys select set hover trigger before_click switch_to_frame] => :page

    attr_reader :url_blacklist, :url_whitelist

    def initialize(options = nil)
      options ||= {}
      self.url_blacklist = options[:url_blacklist]
      self.url_whitelist = options[:url_whitelist]

      super
    end

    def url_whitelist=(patterns)
      @url_whitelist = prepare_wildcards(patterns)
      page.intercept_request if @client && !@url_whitelist.empty?
    end

    def url_blacklist=(patterns)
      @url_blacklist = prepare_wildcards(patterns)
      page.intercept_request if @client && !@url_blacklist.empty?
    end

    def visit(*args)
      goto(*args)
    end

    def status_code
      status
    end

    def find(method, selector)
      find_all(method, selector)
    end

    def property(node, name)
      node.property(name)
    end

    def find_within(node, method, selector)
      resolved = page.command("DOM.resolveNode", nodeId: node.node_id)
      object_id = resolved.dig("object", "objectId")
      find_all(method, selector, { "objectId" => object_id })
    end

    def within_window(locator = nil, &block)
      if Capybara::VERSION.to_f < 3.0
        target_id = window_handles.find do |target_id|
          page = find_or_create_page(target_id)
          locator == page.frame_name
        end
        locator = target_id if target_id
      end

      targets.within_window(locator, &block)
    end

    def browser_error
      evaluate("_cuprite.browserError()")
    end

    def source
      raise NotImplementedError
    end

    def drag(node, other)
      raise NotImplementedError
    end

    def drag_by(node, x, y)
      raise NotImplementedError
    end

    def select_file(node, value)
      node.select_file(value)
    end

    def parents(node)
      evaluate_on(node: node, expression: "_cuprite.parents(this)", by_value: false)
    end

    def visible_text(node)
      evaluate_on(node: node, expression: "_cuprite.visibleText(this)")
    end

    def delete_text(node)
      evaluate_on(node: node, expression: "_cuprite.deleteText(this)")
    end

    def attributes(node)
      value = evaluate_on(node: node, expression: "_cuprite.getAttributes(this)")
      JSON.parse(value)
    end

    def attribute(node, name)
      evaluate_on(node: node, expression: %Q(_cuprite.getAttribute(this, "#{name}")))
    end

    def value(node)
      evaluate_on(node: node, expression: "_cuprite.value(this)")
    end

    def visible?(node)
      evaluate_on(node: node, expression: "_cuprite.isVisible(this)")
    end

    def disabled?(node)
      evaluate_on(node: node, expression: "_cuprite.isDisabled(this)")
    end

    def path(node)
      evaluate_on(node: node, expression: "_cuprite.path(this)")
    end

    def all_text(node)
      node.text
    end

    private

    def find_all(method, selector, within = nil)
      begin
        nodes = if within
          evaluate("_cuprite.find(arguments[0], arguments[1], arguments[2])", method, selector, within)
        else
          evaluate("_cuprite.find(arguments[0], arguments[1])", method, selector)
        end

        nodes.map { |n| n.node? ? n : next }.compact
      rescue Ferrum::JavaScriptError => e
        if e.class_name == "InvalidSelector"
          raise InvalidSelector.new(e.response, method, selector)
        end
        raise
      end
    end

    def prepare_wildcards(wc)
      Array(wc).map do |wildcard|
        if wildcard.is_a?(Regexp)
          wildcard
        else
          wildcard = wildcard.gsub("*", ".*")
          Regexp.new(wildcard, Regexp::IGNORECASE)
        end
      end
    end
  end
end

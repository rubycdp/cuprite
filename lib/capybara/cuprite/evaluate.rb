# frozen_string_literal: true

require "forwardable"

module Capybara::Cuprite
  class Evaluate
    extend Forwardable

    delegate %i(page) => :@targets

    def initialize(targets)
      @targets = targets
    end

    def evaluate(expr, *args)
      response = call(expr, {}, *args)
      process(result: response)
    end

    def evaluate_async(expr, wait_time, *args)
      options = { awaitPromise: true,
                  functionDeclaration: %Q(
                    function() {
                      return new Promise((resolve, reject) => {
                        try {
                          let callback = function(r) { resolve(r) }
                          arguments[arguments.length] = callback
                          #{expr}
                        } catch(error) {
                          reject(error)
                        }
                      });
                    }
                  ) }
      response = call(expr, options, *args)
      process(result: response)
    end

    def execute(expr, *args)
      call(expr, { returnByValue: true }, *args)
      true
    end

    private

    def call(expr, options, *args)
      args = prepare_args(args)
      default_options = { arguments: args,
                          executionContextId: page.execution_context_id,
                          functionDeclaration: %Q(
                            function() { return #{expr} }
                          ) }
      options = default_options.merge(options)
      page.command("Runtime.callFunctionOn", **options)["result"].tap do |response|
        raise JavaScriptError.new(response) if response["subtype"] == "error"
      end
    end

    def prepare_args(args)
      args.map do |arg|
        if arg.is_a?(Node)
          node_id = arg.native.node["nodeId"]
          resolved = page.command("DOM.resolveNode", nodeId: node_id)
          { objectId: resolved["object"]["objectId"] }
        else
          { value: arg }
        end
      end
    end

    def process(result:)
      object_id = result["objectId"]

      case result["type"]
      when "boolean", "number", "string"
        result["value"]
      when "undefined"
        nil
      when "function"
        result["description"]
      when "object"
        case result["subtype"]
        when "node"
          node_id = page.command("DOM.requestNode", objectId: object_id)["nodeId"]
          node = page.command("DOM.describeNode", nodeId: node_id)["node"]
          { "target_id" => page.target_id, "node" => node.merge("nodeId" => node_id) }
        when "array"
          reduce_properties(object_id, Array.new) do |memo, key, value|
            next(memo) unless (Integer(key) rescue nil)
            value = value["objectId"] ? process(result: value) : value["value"]
            memo.insert(key.to_i, value)
          end
        when "date"
          result["description"]
        when "null"
          nil
        else
          reduce_properties(object_id, Hash.new) do |memo, key, value|
            memo.merge(key => value)
          end
        end
      end
    end

    def reduce_properties(object_id, object)
      properties(object_id).reduce(object) do |memo, prop|
        next(memo) unless prop["enumerable"]
        yield(memo, prop["name"], prop["value"])
      end
    end

    def properties(object_id)
      page.command("Runtime.getProperties", objectId: object_id)["result"]
    end
  end
end

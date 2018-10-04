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

    # FIXME: *args, wait_time, async
    def evaluate_async(expression, wait_time, *args)
      expr = "(#{expression.sub(/;?\z/, "")})"
      result = page.command("Runtime.evaluate", expression: expr, returnByValue: true)
      result["result"]["value"]
    end

    def execute(expr, *args)
      call(expr, { returnByValue: true }, *args)
      true
    end

    private

    def call(expr, options, *args)
      args = prepare_args(args)
      expr = prepare_expression(expr)
      default_options = { arguments: args,
                          executionContextId: page.execution_context_id,
                          functionDeclaration: %Q(
                            function() { return #{expr} }
                          ) }
      options = default_options.merge(options)
      page.command("Runtime.callFunctionOn", **options)["result"]
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

    def prepare_expression(expression)
      "(#{expression.sub(/;?\z/, "")})"
    end

    def process(result:)
      object_id = result["objectId"]

      if result["subtype"] == "node"
        node = page.command("DOM.describeNode", objectId: object_id)["node"]
        { "target_id" => page.target_id, "node" => node }
      elsif result["className"] == "Object"
        response = page.command("Runtime.getProperties", objectId: object_id)
        response["result"].reduce(Hash.new) do |base, property|
          next(base) unless property["enumerable"]
          base.merge(property["name"] => property.dig("value", "value"))
        end
      else
        result["value"]
      end
    end
  end
end

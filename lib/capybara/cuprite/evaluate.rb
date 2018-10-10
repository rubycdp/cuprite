# frozen_string_literal: true

require "forwardable"

module Capybara::Cuprite
  class Evaluate
    EXECUTE_OPTIONS = {
      returnByValue: true
    }.freeze
    DEFAULT_OPTIONS = {
      functionDeclaration: %Q(function() { return %s })
    }.freeze
    EVALUATE_ASYNC_OPTIONS = {
      awaitPromise: true,
      functionDeclaration: %Q(
        function() {
         return new Promise((cupriteResolve, cupriteReject) => {
           try {
             let cupriteCallback = function(r) { cupriteResolve(r) };
             arguments[arguments.length] = cupriteCallback;
             arguments.length = arguments.length + 1;
             %s
           } catch(error) {
             cupriteReject(error);
           }
         });
        }
      )
    }.freeze

    extend Forwardable

    delegate %i(page) => :@targets

    def initialize(targets)
      @targets = targets
    end

    def evaluate(expr, *args)
      response = call(expr, nil, *args)
      handle(response)
    end

    def evaluate_async(expr, _wait_time, *args)
      response = call(expr, EVALUATE_ASYNC_OPTIONS, *args)
      handle(response)
    end

    def execute(expr, *args)
      call(expr, EXECUTE_OPTIONS, *args)
      true
    end

    private

    def call(expr, options = nil, *args)
      options ||= {}
      args = prepare_args(args)

      options = DEFAULT_OPTIONS.merge(options)
      options[:functionDeclaration] = options[:functionDeclaration] % expr
      options = options.merge(arguments: args, executionContextId: page.execution_context_id)

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
        elsif arg.is_a?(Hash) && arg["objectId"]
          { objectId: arg["objectId"] }
        else
          { value: arg }
        end
      end
    end

    def handle(response, cleanup = true)
      case response["type"]
      when "boolean", "number", "string"
        response["value"]
      when "undefined"
        nil
      when "function"
        response["description"]
      when "object"
        case response["subtype"]
        when "node"
          node_id = page.command("DOM.requestNode", objectId: response["objectId"])["nodeId"]
          node = page.command("DOM.describeNode", nodeId: node_id)["node"]
          { "target_id" => page.target_id, "node" => node.merge("nodeId" => node_id) }
        when "array"
          reduce_properties(response["objectId"], Array.new) do |memo, key, value|
            next(memo) unless (Integer(key) rescue nil)
            value = value["objectId"] ? handle(value, false) : value["value"]
            memo.insert(key.to_i, value)
          end
        when "date"
          response["description"]
        when "null"
          nil
        else
          reduce_properties(response["objectId"], Hash.new) do |memo, key, value|
            value = value["objectId"] ? handle(value, false) : value["value"]
            memo.merge(key => value)
          end
        end
      end
    ensure
      clean if cleanup
    end

    def reduce_properties(object_id, object)
      if visited?(object_id)
        "(cyclic structure)"
      else
        properties(object_id).reduce(object) do |memo, prop|
          next(memo) unless prop["enumerable"]
          yield(memo, prop["name"], prop["value"])
        end
      end
    end

    def properties(object_id)
      page.command("Runtime.getProperties", objectId: object_id)["result"]
    end

    # Every `Runtime.getProperties` call on the same object returns new object
    # id each time {"objectId":"{\"injectedScriptId\":1,\"id\":1}"} and it's
    # impossible to check that two objects are actually equal. This workaround
    # does equality check only in JS runtime. `_cuprite` can be inavailable here
    # if page is about:blank for example.
    def visited?(object_id)
      expr = %Q(
        let object = arguments[0];
        let callback = arguments[1];

        if (window._cupriteVisitedObjects === undefined) {
          window._cupriteVisitedObjects = [];
        }

        let visited = window._cupriteVisitedObjects;
        if (visited.some(o => o === object)) {
          callback(true);
        } else {
          visited.push(object);
          callback(false);
        }
      )

      response = call(expr, EVALUATE_ASYNC_OPTIONS, { "objectId" => object_id })
      handle(response, false)
    end

    def clean
      execute("delete window._cupriteVisitedObjects")
    end
  end
end

# frozen_string_literal: true

module Capybara::Cuprite
  class Browser
    module Runtime
      EXECUTE_OPTIONS = {
        returnByValue: true,
        functionDeclaration: %Q(function() { %s })
      }.freeze
      DEFAULT_OPTIONS = {
        functionDeclaration: %Q(function() { return %s })
      }.freeze
      EVALUATE_ASYNC_OPTIONS = {
        awaitPromise: true,
        functionDeclaration: %Q(
          function() {
           return new Promise((__resolve, __reject) => {
             try {
               arguments[arguments.length] = r => __resolve(r);
               arguments.length = arguments.length + 1;
               setTimeout(() => __reject(new TimedOutPromise), %s);
               %s
             } catch(error) {
               __reject(error);
             }
           });
          }
        )
      }.freeze

      def evaluate(expr, *args)
        response = call(expr, nil, nil, *args)
        handle(response)
      end

      def evaluate_in(context_id, expr)
        response = call(expr, nil, { executionContextId: context_id })
        handle(response)
      end

      def evaluate_on(node:, expr:, by_value: true, wait: 0)
        object_id = command("DOM.resolveNode", nodeId: node["nodeId"]).dig("object", "objectId")
        options = DEFAULT_OPTIONS.merge(objectId: object_id)
        options[:functionDeclaration] = options[:functionDeclaration] % expr
        options.merge!(returnByValue: by_value)

        @wait = wait if wait > 0

        response = command("Runtime.callFunctionOn", **options)
          .dig("result").tap { |r| handle_error(r) }

        by_value ? response.dig("value") : handle(response)
      end

      def evaluate_async(expr, wait_time, *args)
        response = call(expr, wait_time * 1000, EVALUATE_ASYNC_OPTIONS, *args)
        handle(response)
      end

      def execute(expr, *args)
        call(expr, nil, EXECUTE_OPTIONS, *args)
        true
      end

      private

      def call(expr, wait_time, options = nil, *args)
        options ||= {}
        args = prepare_args(args)

        options = DEFAULT_OPTIONS.merge(options)
        expr = [wait_time, expr] if wait_time
        options[:functionDeclaration] = options[:functionDeclaration] % expr
        options = options.merge(arguments: args)
        unless options[:executionContextId]
          options = options.merge(executionContextId: execution_context_id)
        end

        command("Runtime.callFunctionOn", **options)
          .dig("result").tap { |r| handle_error(r) }
      end

      # FIXME: We should have a central place to handle all type of errors
      def handle_error(result)
        return if result["subtype"] != "error"

        case result["className"]
        when "TimedOutPromise"
          raise ScriptTimeoutError
        when "MouseEventFailed"
          raise MouseEventFailed.new(result["description"])
        else
          raise JavaScriptError.new(result)
        end
      end

      def prepare_args(args)
        args.map do |arg|
          if arg.is_a?(Node)
            node_id = arg.native.node["nodeId"]
            resolved = command("DOM.resolveNode", nodeId: node_id)
            { objectId: resolved["object"]["objectId"] }
          elsif arg.is_a?(Hash) && arg["objectId"]
            { objectId: arg["objectId"] }
          else
            { value: arg }
          end
        end
      end

      def handle(response)
        case response["type"]
        when "boolean", "number", "string"
          response["value"]
        when "undefined"
          nil
        when "function"
          {}
        when "object"
          object_id = response["objectId"]

          case response["subtype"]
          when "node"
            node_id = command("DOM.requestNode", objectId: object_id)["nodeId"]
            node = command("DOM.describeNode", nodeId: node_id)["node"].merge("nodeId" => node_id)
            { "target_id" => target_id, "node" => node }
          when "array"
            check_cyclic = response["className"] != "NodeList"
            reduce_props(object_id, [], check_cyclic) do |memo, key, value|
              next(memo) unless (Integer(key) rescue nil)
              value = value["objectId"] ? handle(value) : value["value"]
              memo.insert(key.to_i, value)
            end
          when "date"
            response["description"]
          when "null"
            nil
          else
            reduce_props(object_id, {}) do |memo, key, value|
              value = value["objectId"] ? handle(value) : value["value"]
              memo.merge(key => value)
            end
          end
        end
      end

      def reduce_props(object_id, to, check_cyclic = true)
        if check_cyclic && cyclic?(object_id).dig("result", "value")
          return "(cyclic structure)"
        else
          props = command("Runtime.getProperties", objectId: object_id)
          props["result"].reduce(to) do |memo, prop|
            next(memo) unless prop["enumerable"]
            yield(memo, prop["name"], prop["value"])
          end
        end
      end

      def cyclic?(object_id)
        command("Runtime.callFunctionOn",
                objectId: object_id,
                returnByValue: true,
                functionDeclaration: "function() { return _cuprite.isCyclic(this); }")
      end
    end
  end
end

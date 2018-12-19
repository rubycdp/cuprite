# frozen_string_literal: true

require "cuprite/browser/web_socket"

module Capybara::Cuprite
  class Browser
    class Client
      def initialize(ws_url, logger)
        @command_id = 0
        @logger = logger
        @subscribed = {}
        @commands = Queue.new
        @ws = WebSocket.new(ws_url, logger)

        @thread = Thread.new do
          while message = @ws.messages.pop
            if method = message["method"]
              block = @subscribed[method]
              block.call(message["params"]) if block
            else
              @commands.push(message)
            end
          end

          @commands.close
        end
      end

      def command(method, params = {})
        message = build_message(method, params)
        @ws.send_message(message)
        response = @commands.pop
        raise DeadBrowser unless response
        handle(response)
      end

      def subscribe(event, &block)
        @subscribed[event] = block
        true
      end

      def close
        @ws.close
        @thread.kill
      end

      private

      def handle(message)
        error, response = message.values_at("error", "result")
        raise BrowserError.new(error) if error
        response
      end

      def build_message(method, params)
        { method: method, params: params }.merge(id: next_command_id)
      end

      def next_command_id
        @command_id += 1
      end
    end
  end
end

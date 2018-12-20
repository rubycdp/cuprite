# frozen_string_literal: true

require "cuprite/browser/web_socket"

module Capybara::Cuprite
  class Browser
    class Client
      class IdError < RuntimeError; end

      def initialize(ws_url, logger)
        @command_id = 0
        @logger = logger
        @subscribed = {}
        @commands = Queue.new
        @ws = WebSocket.new(ws_url, logger)

        @thread = Thread.new do
          while message = @ws.messages.pop
            method, params = message.values_at("method", "params")
            if method
              @subscribed[method]&.(params)
            else
              @commands.push(message)
            end
          end

          @commands.close
        end
      end

      def command(method, params = {})
        id = send_message(method, params)
        begin
          response = @commands.pop
          raise DeadBrowser unless response
          raise IdError if response["id"] != id
          handle(response)
        rescue IdError
          retry
        end
      end

      def subscribe(event, &block)
        @subscribed[event] = block
        true
      end

      def close
        @ws.close
        @thread.kill
      end

      def send_message(method, params)
        message = build_message(method, params)
        @ws.send_message(message)
        message[:id]
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

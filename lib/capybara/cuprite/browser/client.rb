# frozen_string_literal: true

require "forwardable"
require "cuprite/browser/web_socket"

module Capybara::Cuprite
  class Browser
    class Client
      extend Forwardable

      delegate [:close, :subscribe, :messages] => :@web_socket

      def initialize(ws_url, logger)
        @command_id = 0
        @logger = logger
        @web_socket = WebSocket.new(ws_url, logger)
      end

      def command(method, params = {})
        message = build_message(method, params)
        @web_socket.send_message(message)
        response = wait(message[:id])
        handle(response)
      rescue DeadClient
        # FIXME:
        restart
        raise
      end


      def wait(type = nil, params = {}, idle = 0.1)
        loop do
          message = case type
                    when String
                      messages.find { |m| m["method"] == type && params.all? { |k, v| m["params"][k.to_s] == v } }
                    when Integer
                      messages.find { |m| m["id"] == type }
                    else
                      raise ArgumentError.new("First parameter should be `id: Integer` or `event: String`")
                    end

          return message if message

          sleep(idle)
        end
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

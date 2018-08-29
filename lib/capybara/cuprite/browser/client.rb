# frozen_string_literal: true

require "forwardable"
require "cuprite/browser/web_socket"

module Capybara::Cuprite
  class Browser
    class Client
      extend Forwardable

      delegate close: :@web_socket

      def initialize(ws_url, logger)
        @command_id = 0
        @web_socket = WebSocket.new(ws_url, logger)
      end

      def command(method, params = {})
        message = build_message(method, params)
        @web_socket.send_message(message)
        response = wait_response(message[:id])
        handle(response)
      rescue DeadClient
        # FIXME:
        restart
        raise
      end

      def wait(sec = 0.1, event:)
        loop do
          filter_by(method: event).each do |message|
            return message if yield(message["params"])
          end
          sleep(sec)
        end
      end

      private

      def wait_response(id, sec = 0.1)
        loop do
          message = filter_by(id: id)&.first
          return message if message
          sleep(sec)
        end
      end

      def handle(message)
        error, response = message.values_at("error", "result")
        raise BrowserError.new(error) if error
        response
      end

      def filter_by(id: nil, method: nil)
        @web_socket.messages.select do |message|
          id ? message["id"] == id : message["method"] == method
        end
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

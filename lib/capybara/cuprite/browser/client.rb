# frozen_string_literal: true

require "json"
require "net/http"
require "time"

require "cuprite/browser/web_socket"

module Capybara::Cuprite
  class Browser
    class Client
      def initialize(host, port, logger)
        @host, @port = host, port
        @ws = WebSocket.new(ws_url, logger)
      end

      def command(method, params = {})
        command_id = @ws.send(method: method, params: params)
        message = wait(command: command_id)["result"]
        yield message if block_given?
        message
      rescue DeadClient
        restart
        raise
      end

      def wait(sec = 0.1, command: nil, event: nil, params: {})
        loop do
          args = command ? { id: command } : { method: event }
          message = @ws.message_by(args)
          return message if command && message
          return message if event && message && params.all? { |k, v| message["params"][k.to_s] == v }
          sleep(sec)
        end
      end

      private

      def ws_url(try = 0)
        @ws_url ||= try(Errno::ECONNREFUSED) do
          response = Net::HTTP.get(@host, "/json", @port)
          JSON.parse(response)[0]["webSocketDebuggerUrl"]
        end
      end

      def try(error, attempt = 0, attempts = 5)
        yield
      rescue error
        attempt += 1
        sec = 0.1 + attempt / 10.0
        sleep(sec) and retry if attempt < attempts
      end
    end
  end
end

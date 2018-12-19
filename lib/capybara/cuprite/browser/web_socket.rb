# frozen_string_literal: true

require "json"
require "socket"
require "forwardable"
require "websocket/driver"

module Capybara::Cuprite
  class Browser
    class WebSocket
      extend Forwardable

      delegate close: :@driver

      attr_reader :url, :messages

      def initialize(url, logger)
        @url      = url
        @logger   = logger
        uri       = URI.parse(@url)
        @sock     = TCPSocket.new(uri.host, uri.port)
        @driver   = ::WebSocket::Driver.client(self)
        @messages = Queue.new

        @driver.on(:message, &method(:on_message))

        @thread = Thread.new do
          begin
            while data = @sock.readpartial(512)
              @driver.parse(data)
            end
          rescue EOFError
            @messages.close
          end
        end

        @thread.priority = 1

        @driver.start
      end

      def send_message(data)
        json = data.to_json
        @driver.text(json)
        log "\n\n>>> #{json}"
      end

      def on_message(event)
        data = JSON.parse(event.data)
        @messages.push(data)
        log "    <<< #{event.data}\n"
      end

      def write(data)
        @sock.write(data)
      end

      private

      def log(message)
        @logger.write(message) if @logger
      end
    end
  end
end

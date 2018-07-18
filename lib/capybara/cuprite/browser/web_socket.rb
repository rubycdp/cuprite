require "json"
require "socket"
require "websocket/driver"

module Capybara::Cuprite
  class Browser
    class WebSocket
      attr_reader :url, :messages

      def initialize(url)
        @url    = url
        uri     = URI.parse(@url)
        @sock   = TCPSocket.new(uri.host, uri.port)
        @driver = ::WebSocket::Driver.client(self)

        @messages   = []
        @dead       = false
        @command_id = 0

        @driver.on(:message, &method(:on_message))
        @driver.on(:error, &method(:on_error))
        @driver.on(:close, &method(:on_close))

        Thread.abort_on_exception = true

        @thread = Thread.new do
          @driver.parse(@sock.readpartial(512)) until @dead
        end

        @driver.start
      end

      def send(data)
        next_command_id.tap do |id|
          data = data.merge(id: id)
          json = data.to_json
          log ">>> #{json}"
          @driver.text(json)
        end
      end

      def on_message(event)
        log "<<< #{event.data}\n\n"
        data = JSON.parse(event.data)
        raise data["error"]["message"] if data["error"]
        @messages << data
      end

      def on_error(event)
        raise e.message
      end

      def on_close(event)
        log("<<< #{event.code}, #{event.reason}\n\n")
        @dead = true
        @thread.kill
      end

      def message_by(id: nil, method: nil)
        @messages.find do |message|
          id ? message["id"] == id : message["method"] == method
        end
      end

      def write(data)
        @sock.write(data)
      end

      private

      def next_command_id
        @command_id += 1
      end

      def log(message)
        puts(message)
      end
    end
  end
end

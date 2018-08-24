require "json"
require "socket"
require "websocket/driver"

module Capybara::Cuprite
  class Browser
    class WebSocket
      attr_reader :url, :messages

      def initialize(url, logger)
        @url    = url
        @logger = logger
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
          @logger.write ">>> #{json}"
          @driver.text(json)
        end
      end

      def on_message(event)
        @logger.write "    <<< #{event.data}\n\n"
        data = JSON.parse(event.data)
        @messages << data
      end

      # Not sure if CDP uses it at all as all errors go to on_message callback
      # for example: {"error":{"code":-32000,"message":"No node with given id found"},"id":22}
      # FIXME: Raise and close connection and then kill the browser as this
      # would be the error not in the main thread?
      def on_error(event)
        raise event.inspect
      end

      def on_close(event)
        @logger.write "<<< #{event.code}, #{event.reason}\n\n"
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
    end
  end
end

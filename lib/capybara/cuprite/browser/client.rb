# frozen_string_literal: true

require "timeout"
require "cuprite/browser/web_socket"

module Capybara::Cuprite
  class Browser
    class Client
      class IdError < RuntimeError; end

      def initialize(browser, ws_url)
        @command_id = 0
        @subscribed = Hash.new { |h, k| h[k] = [] }
        @browser = browser
        @commands = Queue.new
        @ws = WebSocket.new(ws_url, @browser.logger)

        @thread = Thread.new do
          while message = @ws.messages.pop
            method, params = message.values_at("method", "params")
            if method
              @subscribed[method].each { |b| b.call(params) }
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
        message[:id]
      end

      def wait(id:)
        message = Timeout.timeout(@browser.timeout, TimeoutError) { @commands.pop }
        raise DeadBrowser unless message
        raise IdError if message["id"] != id
        error, response = message.values_at("error", "result")
        raise BrowserError.new(error) if error
        response
      rescue IdError
        retry
      end

      def subscribe(event, &block)
        @subscribed[event] << block
        true
      end

      def close
        @ws.close
        @thread.kill
      end

      private

      def build_message(method, params)
        { method: method, params: params }.merge(id: next_command_id)
      end

      def next_command_id
        @command_id += 1
      end
    end
  end
end

# frozen_string_literal: true

require "timeout"
require "capybara/cuprite/browser/web_socket"

module Capybara::Cuprite
  class Browser
    class Client

      def initialize(browser, ws_url)
        @command_id = 0
        @subscribed = Hash.new { |h, k| h[k] = [] }
        @browser = browser
        @commands = {}
        @mutex = Mutex.new
        @resource = ConditionVariable.new
        @ws = WebSocket.new(ws_url, @browser.logger)

        @thread = Thread.new do
          while message = @ws.messages.pop
            method, params = message.values_at("method", "params")
            if method
              @subscribed[method].each { |b| b.call(params) }
            else
              @mutex.synchronize do
                @commands[message["id"]] = message
                @resource.broadcast
              end
            end
          end
        end
      end

      def command(method, params = {})
        message = build_message(method, params)
        @ws.send_message(message)
        message[:id]
      end

      def wait(id:)
        message = nil
        Timeout.timeout(@browser.timeout, TimeoutError) do
          message = @mutex.synchronize { @commands.delete(id) }
          while !message
            message = @mutex.synchronize do
              @resource.wait(@mutex)
              @commands.delete(id)
            end
          end
        end
        raise DeadBrowser unless message
        error, response = message.values_at("error", "result")
        raise BrowserError.new(error) if error
        response
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

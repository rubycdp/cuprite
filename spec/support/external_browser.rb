module Spec
  module Support
    module ExternalBrowser
      def wait_for_connection(host, port)
        tries = 0

        loop do
          begin
            Socket.tcp(host, port, connect_timeout: 3) {}
            break
          rescue Errno::ECONNREFUSED
            raise if tries >= 50
            tries += 1
            sleep 0.1
          end
        end
      end

      def with_external_browser
        url = URI.parse("http://127.0.0.1:32001")
        opts = { host: url.host, port: url.port, window_size: [1400, 1400], headless: true }
        process = Capybara::Cuprite::Browser::Process.new(opts)

        begin
          process.start
          yield url.to_s
        ensure
          process.stop
        end
      end
    end
  end
end

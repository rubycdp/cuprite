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
        pid = nil
        tmp = nil

        begin

          tmp = Dir.mktmpdir
          remote_debugging_port = 32222
          args = "--user-data-dir=#{tmp} --remote-debugging-port=#{remote_debugging_port}"
          exe = Capybara::Cuprite::Browser::Process.detect_browser_path
          pid = Process.spawn("#{exe} #{args}", out: File::NULL)
          wait_for_connection('localhost', remote_debugging_port)

          url = "http://localhost:#{remote_debugging_port}"
          yield url
        ensure
          Process.kill('SIGTERM', pid)
          FileUtils.rm_f tmp
        end
      end
    end
  end
end

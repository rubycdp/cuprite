# frozen_string_literal: true

require "cliver"

module Capybara::Cuprite
  class Browser
    class Process
      KILL_TIMEOUT = 2

      BROWSER_PATH = "chrome"
      BROWSER_HOST = "127.0.0.1"
      BROWSER_PORT = "0"

      # Chromium command line options
      # https://peter.sh/experiments/chromium-command-line-switches/
      DEFAULT_OPTIONS = {
        "headless" => nil,
        "disable-gpu" => nil,
        "window-size" => "1024,768",
        "hide-scrollbars" => nil,
        "mute-audio" => nil,
        # Note: --no-sandbox is not needed if you properly setup a user in the container.
        # https://github.com/ebidel/lighthouse-ci/blob/master/builder/Dockerfile#L35-L40
        # "no-sandbox" => nil,
        "disable-web-security" => nil,
        "remote-debugging-port" => BROWSER_PORT,
        "remote-debugging-address" => BROWSER_HOST
      }.freeze

      def self.start(*args)
        new(*args).tap { |s| s.start }
      end

      def self.process_killer(pid)
        proc do
          begin
            if Capybara::Cuprite.windows?
              ::Process.kill("KILL", pid)
            else
              ::Process.kill("TERM", pid)
              start = Time.now
              while ::Process.wait(pid, ::Process::WNOHANG).nil?
                sleep 0.05
                next unless (Time.now - start) > KILL_TIMEOUT
                ::Process.kill("KILL", pid)
                ::Process.wait(pid)
                break
              end
            end
          rescue Errno::ESRCH, Errno::ECHILD
          end
        end
      end

      def initialize(options)
        @path    = Cliver.detect(options[:path] || BROWSER_PATH)
        @options = DEFAULT_OPTIONS.merge(options.fetch(:browser, {}))
      end

      def start
        @output = []
        @read_io, @write_io = IO.pipe

        @out_thread = Thread.new do
          while !@read_io.eof? && (data = @read_io.readpartial(512))
            @output << data
          end
        end

        process_options = { in: File::NULL }
        process_options[:pgroup] = true unless Capybara::Cuprite.windows?
        if Capybara::Cuprite.mri?
          process_options[:out] = process_options[:err] = @write_io
        end

        redirect_stdout do
          cmd = [@path] + @options.map { |k, v| v.nil? ? "--#{k}" : "--#{k}=#{v}" }
          @pid = ::Process.spawn(*cmd, process_options)
          ObjectSpace.define_finalizer(self, self.class.process_killer(@pid))
        end
      end

      def stop
        return unless @pid
        kill
        ObjectSpace.undefine_finalizer(self)
      end

      def restart
        stop
        start
      end

      def host
        @host ||= ws_url.host
      end

      def port
        @port ||= ws_url.port
      end

      def ws_url
        @ws_url ||= begin
          regexp = /DevTools listening on (ws:\/\/.*)/
          sleep 0.1 until url = @output.find { |s| s.match?(regexp) }
          ws_url = Addressable::URI.parse(url.match(regexp)[1])
          @out_thread.kill
          close_io
          ws_url
        end
      end

      private

      def redirect_stdout
        if Capybara::Cuprite.mri?
          yield
        else
          begin
            prev = STDOUT.dup
            $stdout = @write_io
            STDOUT.reopen(@write_io)
            yield
          ensure
            STDOUT.reopen(prev)
            $stdout = STDOUT
            prev.close
          end
        end
      end

      def kill
        self.class.process_killer(@pid).call
        @pid = nil
      end

      def close_io
        [@write_io, @read_io].each do |io|
          begin
            io.close unless io.closed?
          rescue IOError
            raise unless RUBY_ENGINE == 'jruby'
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require "cliver"

module Capybara::Cuprite
  class Browser
    class Process
      KILL_TIMEOUT = 2

      BROWSER_PATH = ENV.fetch("BROWSER_PATH", "chrome")
      BROWSER_HOST = "127.0.0.1"
      BROWSER_PORT = "0"

      # Chromium command line options
      # https://peter.sh/experiments/chromium-command-line-switches/
      DEFAULT_OPTIONS = {
        "headless" => nil,
        "disable-gpu" => nil,
        "hide-scrollbars" => nil,
        "mute-audio" => nil,
        # Note: --no-sandbox is not needed if you properly setup a user in the container.
        # https://github.com/ebidel/lighthouse-ci/blob/master/builder/Dockerfile#L35-L40
        # "no-sandbox" => nil,
        "enable-automation" => nil,
        "disable-web-security" => nil,
      }.freeze

      attr_reader :host, :port, :ws_url, :pid, :path, :options

      def self.start(*args)
        new(*args).tap(&:start)
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
        @options = options.fetch(:browser, {})

        detect_browser_path

        window_size = options.fetch(:window_size, [1024, 768])
        @options = @options.merge("window-size" => window_size.join(","))

        port = options.fetch(:port, BROWSER_PORT)
        @options = @options.merge("remote-debugging-port" => port)

        host = options.fetch(:host, BROWSER_HOST)
        @options = @options.merge("remote-debugging-address" => host)

        @options = DEFAULT_OPTIONS.merge(@options)
      end

      def start
        read_io, write_io = IO.pipe
        process_options = { in: File::NULL }
        process_options[:pgroup] = true unless Capybara::Cuprite.windows?
        if Capybara::Cuprite.mri?
          process_options[:out] = process_options[:err] = write_io
        end

        redirect_stdout(write_io) do
          cmd = [@path] + @options.map { |k, v| v.nil? ? "--#{k}" : "--#{k}=#{v}" }
          @pid = ::Process.spawn(*cmd, process_options)
          ObjectSpace.define_finalizer(self, self.class.process_killer(@pid))
        end

        parse_ws_url(read_io)
      ensure
        close_io(read_io, write_io)
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

      def detect_browser_path
        exe = @options[:path] || BROWSER_PATH
        @path = Cliver.detect(exe)

        unless @path
          message = "Could not find an executable `#{exe}`. Try to make it " \
                    "available on the PATH or set environment varible for " \
                    "example BROWSER_PATH=\"/Applications/Chromium.app/Contents/MacOS/Chromium\""
          raise Cliver::Dependency::NotFound.new(message)
        end
      end

      private

      def redirect_stdout(write_io)
        if Capybara::Cuprite.mri?
          yield
        else
          begin
            prev = STDOUT.dup
            $stdout = write_io
            STDOUT.reopen(write_io)
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

      def parse_ws_url(read_io, timeout = 3)
        output = ""
        start = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC)
        max_time = start + timeout
        regexp = /DevTools listening on (ws:\/\/.*)/
        while (now = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC)) < max_time
          begin
            output += read_io.read_nonblock(512)
          rescue IO::WaitReadable
            IO.select([read_io], nil, nil, max_time - now)
          else
            if output.match(regexp)
              @ws_url = Addressable::URI.parse(output.match(regexp)[1])
              @host = @ws_url.host
              @port = @ws_url.port
              break
            end
          end
        end

        unless @ws_url
          raise "Chrome process did not produce websocket url within #{timeout} seconds"
        end
      end

      def close_io(*ios)
        ios.each do |io|
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

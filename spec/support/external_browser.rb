module Spec
  module Support
    module ExternalBrowser
      def with_external_browser
        url = URI.parse("http://127.0.0.1:32001")
        opts = { host: url.host, port: url.port, window_size: [1400, 1400], headless: true }
        process = Ferrum::Browser::Process.new(opts)

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

# frozen_string_literal: true

require "pdf/reader"

describe Capybara::Cuprite::Driver do
  let(:mobile) { false }
  include Spec::Support::ExternalBrowser

  around do |example|
    @session = mobile ? TestSessions::CupriteMobile : TestSessions::Cuprite
    @driver = @session.driver
    example.run
  ensure
    @driver.reset!
  end

  def session_url(path)
    server = @session.server
    "http://#{server.host}:#{server.port}#{path}"
  end

  describe ".new" do
    context "with emulate:" do
      let(:mobile) { true }

      it "emulates a mobile browser" do
        @session.visit("/cuprite/mobile")
        expect(@session).to have_text("I am a mobile.")
        expect(@session).to have_no_text("I am a desktop.")
        expect(@session.evaluate_script("'ontouchstart' in window || navigator.maxTouchPoints > 0")).to be_truthy
      end

      it "applies the device scale factor" do
        @session.visit("/cuprite/mobile")
        expect(@session.evaluate_script("window.devicePixelRatio")).to eq(3)
      end

      it "keeps emulating a mobile browser after resizing the window" do
        @session.visit("/cuprite/mobile")
        @session.current_window.resize_to(414, 896)

        expect(@session).to have_text("I am a mobile.")
        expect(@session.evaluate_script("navigator.maxTouchPoints > 0")).to be(true)
        expect(@session.evaluate_script("window.devicePixelRatio")).to eq(3)
      end

      it "sends the device user agent" do
        @session.visit("/cuprite/headers")

        expect(@driver.html).to include("USER_AGENT: Mozilla/5.0 (iPhone; CPU iPhone OS")
        expect(@session.evaluate_script("navigator.userAgent")).to start_with("Mozilla/5.0 (iPhone;")
      end

      it "keeps the device user agent when other headers are set" do
        @driver.browser.headers.set("DV" => "hello")
        @session.visit("/cuprite/headers")

        expect(@driver.html).to include("DV: hello")
        expect(@session.evaluate_script("navigator.userAgent")).to start_with("Mozilla/5.0 (iPhone;")
      end
    end

    context "with emulate: and explicit options" do
      let(:session) { Capybara::Session.new(:cuprite_pixel, TestApp) }

      before do
        Capybara.register_driver(:cuprite_pixel) do |app|
          Capybara::Cuprite::Driver.new(app, emulate: :pixel_9, scale_factor: 1)
        end
      end

      after { session.driver.quit }

      it "lets the options override the device" do
        session.visit("/cuprite/mobile")

        expect(session).to have_text("I am a mobile.")
        expect(session.evaluate_script("window.devicePixelRatio")).to eq(1)
      end

      it "fills in the running Chrome version" do
        session.visit("/cuprite/mobile")
        version = session.driver.browser.version.user_agent[%r{Chrome/(\S+)}, 1]

        expect(session.evaluate_script("navigator.userAgent")).to eq(
          "Mozilla/5.0 (Linux; Android 14; Pixel 9) AppleWebKit/537.36 (KHTML, like Gecko) " \
          "Chrome/#{version} Mobile Safari/537.36"
        )
      end
    end

    it "does not emulate a mobile browser without emulate:" do
      @session.visit("/cuprite/mobile")
      expect(@session).to have_text("I am a desktop.")
      expect(@session).to have_no_text("I am a mobile.")
      expect(@session.evaluate_script("'ontouchstart' in window || navigator.maxTouchPoints > 0")).to be_falsy
    end

    it "raises an error for an unknown device to emulate" do
      driver = Capybara::Cuprite::Driver.new(nil, emulate: :nokia_3310)

      expect { driver.browser }.to raise_error(ArgumentError, /Unknown device to emulate: :nokia_3310/)
    end

    it "sets a viewport size of 1024x768 by default" do
      @session.visit("/")
      expect(
        @driver.evaluate_script("[window.innerWidth, window.innerHeight]")
      ).to eq([1024, 768])
    end

    it "sets the viewport size from :window_size" do
      Capybara.register_driver :cuprite_with_custom_window_size do |app|
        Capybara::Cuprite::Driver.new(app, window_size: [800, 600])
      end
      driver = Capybara::Session.new(:cuprite_with_custom_window_size, TestApp).driver
      driver.visit(session_url("/"))
      expect(
        driver.evaluate_script("[window.innerWidth, window.innerHeight]")
      ).to eq([800, 600])
    ensure
      driver&.quit
    end

    it "leaves the window size to the browser with window_size: nil" do
      Capybara.register_driver :cuprite_without_window_size do |app|
        Capybara::Cuprite::Driver.new(app, window_size: nil)
      end
      driver = Capybara::Session.new(:cuprite_without_window_size, TestApp).driver
      driver.visit(session_url("/"))
      default_size = driver.evaluate_script("[window.innerWidth, window.innerHeight]")
      expect(default_size).not_to eq([1024, 768])

      driver.resize_window_to(driver.current_window_handle, 800, 600)
      expect(driver.evaluate_script("[window.innerWidth, window.innerHeight]")).to eq([800, 600])

      driver.reset!
      driver.visit(session_url("/"))
      expect(driver.evaluate_script("[window.innerWidth, window.innerHeight]")).to eq(default_size)
    ensure
      driver&.quit
    end

    it "extends the browser's world with :extensions" do
      extended_driver = Capybara::Cuprite::Driver.new(
        @session.app,
        extensions: [File.expand_path("support/geolocation.js", __dir__)]
      )

      extended_driver.visit session_url("/cuprite/requiring_custom_extension")

      expect(
        extended_driver.html
      ).to include(%(Location: <span id="location">1,-1</span>))

      expect(
        extended_driver.evaluate_script(%(document.getElementById("location").innerHTML))
      ).to eq("1,-1")

      expect(
        extended_driver.evaluate_script("navigator.geolocation")
      ).to_not eq(nil)
    ensure
      extended_driver.quit
    end

    it "connects to an external browser with :url" do
      with_external_browser do |url|
        driver = Capybara::Cuprite::Driver.new(@driver.app, url: url)
        driver.visit session_url("/")
        expect(driver.html).to include("Hello world!")
      ensure
        driver&.quit
      end
    end

    it "saves downloads to Capybara.save_path by default" do
      @driver.browser.downloads.wait { @session.visit("/cuprite/attachment.txt") }

      file = @driver.browser.downloads.files.last
      expect(file["suggestedFilename"]).to eq("attachment.txt")
      expect(file["state"]).to eq("completed")
      expect(File.read(File.join(Capybara.save_path, "attachment.txt"))).to eq("attachment contents")
    end

    context "with js_errors: true" do
      let(:driver) { Capybara::Cuprite::Driver.new(@session.app, js_errors: true) }

      it "propagates a Javascript error with its stack trace to a ruby exception" do
        expect do
          driver.browser.evaluate("(function browserError() { throw new Error('zomg') })()")
        end.to raise_error(Ferrum::JavaScriptError) { |e|
          expect(e.message).to include("Error: zomg")
          expect(e.message).to include("at browserError")
        }
      end

      it "propagates an asynchronous Javascript error on the page to a ruby exception" do
        expect do
          driver.execute_script "setTimeout(function() { omg }, 0)"
          sleep 0.01
          driver.execute_script ""
        end.to raise_error(Ferrum::JavaScriptError, /ReferenceError.*omg/)
      end

      it "propagates a synchronous Javascript error on the page to a ruby exception" do
        expect do
          driver.execute_script "omg"
        end.to raise_error(Ferrum::JavaScriptError, /ReferenceError.*omg/)
      end

      it "does not re-raise a Javascript error if it is rescued" do
        expect do
          driver.execute_script "setTimeout(function() { omg }, 0)"
          sleep 0.01
          driver.execute_script ""
        end.to raise_error(Ferrum::JavaScriptError)

        # should not raise again
        expect(driver.evaluate_script("1+1")).to eq(2)
      end

      it "propagates a Javascript error during page load to a ruby exception" do
        expect { driver.visit session_url("/cuprite/js_error") }.to raise_error(Ferrum::JavaScriptError)
      end
    end

    it "does not propagate a Javascript error to ruby with js_errors: false" do
      driver = Capybara::Cuprite::Driver.new(@session.app, js_errors: false)
      driver.visit session_url("/cuprite/js_error")
      driver.execute_script "setTimeout(function() { omg }, 0)"
      sleep 0.1
      expect(driver.html).to include("hello")
    ensure
      driver&.quit
    end

    it "does not propagate a Javascript error to ruby after a restart with js_errors: false" do
      driver = Capybara::Cuprite::Driver.new(@session.app, js_errors: false)
      driver.browser.restart
      driver.visit session_url("/cuprite/js_error")
      driver.execute_script "setTimeout(function() { omg }, 0)"
      sleep 0.1
      expect(driver.html).to include("hello")
    ensure
      driver&.quit
    end
  end

  describe "#visit" do
    it "raises with the pending connections when the page times out" do
      @driver.browser.page # attach first so the low timeout covers visit only
      old_timeout = @driver.browser.timeout
      @driver.browser.timeout = 0.1
      expect do
        @driver.visit(session_url("/cuprite/really_slow"))
      end.to raise_error(
        Ferrum::StatusError,
        %r{there are still pending connections: http://.*/cuprite/really_slow}
      )
    ensure
      @driver.browser.timeout = old_timeout
    end

    it "reports the pending resource requests of a page that times out" do
      old_timeout = @session.driver.browser.timeout
      @session.driver.browser.timeout = 2
      expect do
        @session.visit("/cuprite/visit_timeout")
      end.to raise_error(
        Ferrum::StatusError,
        %r{there are still pending connections: http://.*/cuprite/really_slow}
      )
    ensure
      @session.driver.browser.timeout = old_timeout
    end

    it "warns when Ferrum::PendingConnectionsError is rescued" do
      @driver.browser.page
      old_timeout = @driver.browser.timeout
      @driver.browser.timeout = 0.1
      expect do
        @driver.visit(session_url("/cuprite/really_slow"))
      rescue Ferrum::PendingConnectionsError
        nil
      end.to output(/#{__FILE__}:\d+: warning: Ferrum::PendingConnectionsError is deprecated/).to_stderr
    ensure
      @driver.browser.timeout = old_timeout
    end

    it "does not raise with pending_connection_errors: false" do
      driver = Capybara::Cuprite::Driver.new(@session.app, pending_connection_errors: false, timeout: 0.5)
      expect { driver.visit(session_url("/cuprite/really_slow")) }.not_to raise_error
    ensure
      driver&.quit
    end

    it "does not report open resources where there are none" do
      old_timeout = @session.driver.browser.timeout
      begin
        @session.driver.browser.timeout = 4
        expect { @session.visit("/cuprite/really_slow") }.not_to raise_error
      ensure
        @session.driver.browser.timeout = old_timeout
      end
    end

    it "handles hash changes" do
      @session.visit "/#omg"
      expect(@session.current_url).to match(%r{/#omg$})
      @session.execute_script <<-JS
        window.onhashchange = function() { window.last_hashchange = window.location.hash }
      JS
      @session.visit "/#foo"
      expect(@session.current_url).to match(%r{/#foo$})
      expect(@session.evaluate_script("window.last_hashchange")).to eq("#foo")
    end

    it "sets base_url for cookies to the visited host" do
      port = @session.server.port
      @session.visit("http://localhost:#{port}/")
      @driver.browser.cookies.set(name: "capybara", value: "localhost")

      @session.visit("http://localhost:#{port}/cuprite/get_cookie")
      expect(@driver.html).to include("localhost")

      @session.visit("http://127.0.0.1:#{port}/cuprite/get_cookie")
      expect(@driver.html).not_to include("localhost")
    end
  end

  describe "#reset!" do
    it "sets base_url for cookies to the server" do
      @driver.browser.cookies.set(name: "capybara", value: "omg")
      @session.visit("/get_cookie")
      expect(@driver.html).to include("omg")
    end

    it "sets base_url for cookies to Capybara.app_host" do
      old_app_host = Capybara.app_host
      Capybara.app_host = "http://localhost/cuprite"
      @driver.reset!
      @driver.browser.cookies.set(name: "capybara", value: "app_host")

      port = @session.server.port
      @session.visit("http://localhost:#{port}/cuprite/get_cookie")
      expect(@driver.html).to include("app_host")

      @session.visit("http://127.0.0.1:#{port}/cuprite/get_cookie")
      expect(@driver.html).not_to include("app_host")
    ensure
      Capybara.app_host = old_app_host
    end

    it "forgets downloaded files" do
      @driver.browser.downloads.wait { @session.visit("/cuprite/attachment.txt") }
      @driver.reset!

      expect(@driver.browser.downloads.files).to be_empty
    end

    it "forgets console messages" do
      @session.visit("/cuprite/console_log")
      @driver.reset!

      expect(@driver.browser.console).to be_empty
    end

    it "clears local storage" do
      @session.visit "/"
      @session.execute_script <<-JS
        localStorage.setItem("key", "value");
      JS
      value = @session.evaluate_script <<-JS
        localStorage.getItem("key");
      JS

      expect(value).to eq("value")

      @driver.reset!

      @session.visit "/"
      value = @session.evaluate_script <<-JS
        localStorage.getItem("key");
      JS
      expect(value).to be_nil
    end
  end

  describe "#current_url" do
    let(:request_uri) { URI.parse(@session.current_url).request_uri }

    it "supports whitespace characters" do
      @session.visit "/cuprite/arbitrary_path/200/foo%20bar%20baz"
      expect(@session.current_path).to eq("/cuprite/arbitrary_path/200/foo%20bar%20baz")
    end

    it "supports escaped characters" do
      @session.visit "/cuprite/arbitrary_path/200/foo?a%5Bb%5D=c"
      expect(request_uri).to eq("/cuprite/arbitrary_path/200/foo?a%5Bb%5D=c")
    end

    it "supports url in parameter" do
      @session.visit "/cuprite/arbitrary_path/200/foo%20asd?a=http://example.com/asd%20asd"
      expect(request_uri).to eq("/cuprite/arbitrary_path/200/foo%20asd?a=http://example.com/asd%20asd")
    end

    it "supports restricted characters ' []:/+&='" do
      @session.visit "/cuprite/arbitrary_path/200/foo?a=%20%5B%5D%3A%2F%2B%26%3D"
      expect(request_uri).to eq("/cuprite/arbitrary_path/200/foo?a=%20%5B%5D%3A%2F%2B%26%3D")
    end

    it "returns about:blank when on about:blank" do
      @session.visit "about:blank"
      expect(@session.current_url).to eq("about:blank")
    end
  end

  describe "#frame_url" do
    it "returns the url of the current frame" do
      @session.visit "/cuprite/frames"

      @session.within_frame(0) do
        expect(@session.driver.frame_url).to end_with("/cuprite/slow")
        expect(@session.driver.current_url).to end_with("/cuprite/frames")
      end
      expect(@session.driver.frame_url).to end_with("/cuprite/frames")
      expect(@session.driver.current_url).to end_with("/cuprite/frames")
    end
  end

  describe "#status_code" do
    it "returns the status of the response" do
      @session.visit("/cuprite/status/500")
      expect(@driver.status_code).to eq(500)
    end

    it "returns the status of a page with a few resources" do
      @session.visit("/cuprite/with_different_resources")
      expect(@driver.status_code).to eq(200)
    end

    it "returns the status after a redirect" do
      @session.visit("/cuprite/redirect")
      expect(@driver.status_code).to eq(200)
    end

    it "returns the status of a page opened by a link" do
      @session.visit "/cuprite/with_different_resources"

      @session.click_link "Go to 500"

      expect(@session.status_code).to eq(500)
    end

    it "returns the status of the last of a few pages" do
      @session.visit "/cuprite/with_different_resources"

      @session.click_link "Go to 201"
      @session.click_link "Do redirect"
      @session.click_link "Go to 402"

      expect(@session.status_code).to eq(402)
    end
  end

  describe "#go_back" do
    it "goes back when history state has been pushed" do
      @session.visit("/")
      @session.execute_script(%(window.history.pushState({foo: "bar"}, "title", "bar2.html");))
      expect(@session).to have_current_path("/bar2.html")
      expect { @session.go_back }.not_to raise_error
      expect(@session).to have_current_path("/")
    end
  end

  describe "#go_forward" do
    it "goes forward when history state is used" do
      @session.visit("/")
      @session.execute_script(%(window.history.pushState({foo: "bar"}, "title", "bar2.html");))
      expect(@session).to have_current_path("/bar2.html")
      # don't use #go_back here to isolate the test
      @session.execute_script("window.history.go(-1);")
      expect(@session).to have_current_path("/")
      expect { @session.go_forward }.not_to raise_error
      expect(@session).to have_current_path("/bar2.html")
    end
  end

  describe "#find_css" do
    it "supports position filters" do
      @session.visit("/cuprite/click_coordinates")

      box = @session.find(:css, "#box")
      log = @session.find(:css, "#log")

      expect(@session).to have_element(id: "box", above: log)
      expect(@session).to have_element(id: "log", below: box)
      expect(@session).not_to have_element(id: "box", below: log)
      expect(@session).not_to have_element(id: "log", above: box)
    end

    it "does not raise error when asserting svg elements with a count that is not what is in the dom" do
      @session.visit("/cuprite/with_js")
      expect { @session.has_css?("svg circle", count: 2) }.to_not raise_error
      expect(@session).to_not have_css("svg circle", count: 2)
    end

    it "raises ElementNotFound when the page overrides Array#toJSON" do
      @session.visit("/cuprite/index")
      array_munge = <<-JS
        Array.prototype.toJSON = function() {
          return "ohai";
        }
      JS
      @session.execute_script array_munge

      expect { @session.find(:css, "username") }.to raise_error(Capybara::ElementNotFound)
    end

    it "raises InvalidSelector for an invalid selector" do
      @session.visit "/cuprite/table"
      expect { @session.find(:css, "table tr:last") }.to raise_error(Capybara::Cuprite::InvalidSelector)
    end

    context "with finder hints" do
      before { @session.visit("/cuprite/find_hints") }

      def ids(nodes)
        nodes.map { |node| node[:id] }
      end

      def matched_ids(nodes)
        ids(nodes.reject { |node| node.initial_cache.key?(:all_text) })
      end

      def no_matches_message(description)
        texts = ["Shown item", "", "Splitword", "Zero\u200bwidth", "SHOUTED", "Spaced out", "Non breaking"]
        "expected to find #{description} but there were no matches. " \
          "Also found #{texts.map(&:inspect).join(', ')}, which matched the selector but not all filters. "
      end

      it "answers visibility, styles and position in the initial cache" do
        shown, hidden = @driver.find_css("#shown, #hidden", uses_visibility: true,
                                                            styles: { color: "red" },
                                                            position: true)

        expect(shown.initial_cache).to include(visible: true, style: { "color" => "rgb(255, 0, 0)" })
        expect(shown.initial_cache[:position]).to eq(shown.rect)
        expect(hidden.initial_cache).to include(visible: false)
      end

      it "answers visibility for each node when they share ancestors" do
        @session.execute_script("document.getElementById('dialog').showModal()")
        nodes = @driver.find_css("#faded p", uses_visibility: true)

        expect(nodes.to_h { |node| [node[:id], node.initial_cache[:visible]] })
          .to eq("before_dialog" => false, "in_dialog" => true, "after_dialog" => false)
      end

      it "leaves the initial cache empty without hints" do
        expect(@driver.find_css("li").map(&:initial_cache)).to all(eq({}))
      end

      it "keeps only the nodes holding every text" do
        expect(ids(@driver.find_css("li", texts: %w[Shown item]))).to eq(%w[shown])
        expect(ids(@driver.find_css("li", texts: %w[Hidden]))).to eq(%w[hidden])
        expect(matched_ids(@driver.find_css("li", texts: %w[shown]))).to be_empty
      end

      it "keeps the ancestors of a node holding every text, in document order" do
        expect(ids(@driver.find_css("#items, #split, #split span", texts: %w[Splithidden]))).to eq(%w[items split])
      end

      it "matches the visible text only when visibility is asked for" do
        expect(matched_ids(@driver.find_css("li", texts: %w[Splitword]))).to be_empty
        expect(ids(@driver.find_css("li", texts: %w[Splitword], uses_visibility: true))).to eq(%w[split])
      end

      it "matches the visible text of nodes that share ancestors" do
        expect(ids(@driver.find_css("ul, li", texts: %w[SHOUTED], uses_visibility: true))).to eq(%w[items shouted])
        expect(matched_ids(@driver.find_css("ul, li", texts: %w[Splitword Hidden], uses_visibility: true))).to be_empty
      end

      it "finds what Capybara matches on text" do
        expect(@session.find(:css, "li", text: "Splitword")[:id]).to eq("split")
        expect(@session.find(:css, "li", text: "Zerowidth", visible: :all)[:id]).to eq("zero_width")
        expect(@session.find(:css, "li", text: "SHOUTED")[:id]).to eq("shouted")
        expect(@session.find(:css, "li", text: "Spaced out")[:id]).to eq("spaced")
        expect(@session.find(:css, "li", text: "Non breaking")[:id]).to eq("non_breaking")
      end

      it "skips what Capybara doesn't match on text" do
        expect(@session).to have_no_css("li", text: "shown item")
        expect(@session).to have_no_css("li", text: "shouted")
        expect(@session).to have_no_css("li", text: "Zerowidth")
        expect(@session).to have_no_css("li", text: "Hidden item")
      end

      it "returns the nodes with the texts Capybara reads when none hold every text" do
        nodes = @driver.find_css("li", texts: %w[Missing], uses_visibility: true)

        expect(ids(nodes)).to eq(%w[shown hidden split zero_width shouted spaced non_breaking])
        expect(nodes.first.initial_cache).to eq(visible: true, all_text: "Shown item", visible_text: "Shown item")
        expect(nodes[1].initial_cache).to eq(visible: false, all_text: "Hidden item", visible_text: nil)
      end

      it "returns at most 50 nodes when none hold every text" do
        @session.execute_script(<<~JS)
          document.getElementById("items").innerHTML = "<li>Row</li>".repeat(60);
        JS

        expect(@driver.find_css("li", texts: %w[Missing]).size).to eq(50)
      end

      it "reads the text of a node holding every text live" do
        node = @driver.find_css("#shown", texts: %w[Shown], uses_visibility: true).first
        @session.execute_script("document.getElementById('shown').textContent = 'Changed'")

        expect([node.all_text, node.visible_text]).to eq(%w[Changed Changed])
      end

      it "describes a failed find as Capybara does without hints" do
        expect { @session.find(:css, "#items li", text: "Missing", wait: 0) }
          .to raise_error(Capybara::ElementNotFound, 'Unable to find visible css "#items li" with text "Missing"')
      end

      it "describes a failed assert_selector as Capybara does without hints" do
        expect { @session.assert_selector(:css, "#items li", text: "Missing", wait: 0) }
          .to raise_error(Capybara::ExpectationNotMet,
                          no_matches_message(%(visible css "#items li" with text "Missing")))
      end

      it "describes a failed assert_selector for all nodes as Capybara does without hints" do
        items = @session.find(:css, "#items")

        expect { items.assert_selector(:css, "li", text: "Missing", visible: :all, wait: 0) }
          .to raise_error(Capybara::ExpectationNotMet,
                          no_matches_message(%(css "li" with text "Missing" within #{items.inspect})))
      end

      it "returns nothing when nothing matches" do
        expect(@driver.find_css("#missing", uses_visibility: true, position: true)).to be_empty
      end

      it "filters the rest of a result by the hints from when it was found, as Selenium does" do
        result = @session.all(:css, "#items li", minimum: 1)
        @session.execute_script("document.getElementById('split').style.display = 'none'")

        expect(ids(result)).to include("split")
      end
    end
  end

  describe "#find_xpath" do
    it "finds nodes when the page replaces JSON" do
      @session.visit("/cuprite/index")
      @session.execute_script("JSON = {};")
      expect { @session.find(:link, "JS redirect") }.not_to raise_error
    end

    it "raises InvalidSelector for an invalid xpath" do
      @session.visit("/cuprite/with_js")
      expect { @session.find(:xpath, "#remove_me") }.to raise_error(Capybara::Cuprite::InvalidSelector)
    end

    it "finds a link with exact_text: true" do
      @session.visit "/with_html"
      expect(@session.find_link("A link", exact_text: true)[:href]).to end_with("/with_simple_html")
    end

    it "returns nothing with finder hints when nothing matches" do
      @session.visit("/cuprite/find_hints")
      expect(@driver.find_xpath("//li[@id='missing']", uses_visibility: true)).to be_empty
    end
  end

  describe "#evaluate_script" do
    it "returns an element" do
      @session.visit("/cuprite/send_keys")
      element = @session.driver.evaluate_script(%(document.getElementById("empty_input")))
      expect(element).to eq(@session.find(:id, "empty_input"))
    end

    it "returns structures with elements" do
      @session.visit("/cuprite/send_keys")
      result = @session.driver.evaluate_script <<~JS
        {
          a: document.getElementById("empty_input"),
          b: { c: document.querySelectorAll("#empty_textarea, #filled_textarea") }
        }
      JS

      expect(result).to eq(
        "a" => @session.driver.find_css("#empty_input").first,
        "b" => {
          "c" => @session.driver.find_css("#empty_textarea, #filled_textarea")
        }
      )
    end

    it "returns values properly" do
      expect(@session.evaluate_script("null")).to be_nil
      expect(@session.evaluate_script("false")).to be false
      expect(@session.evaluate_script("true")).to be true
      expect(@session.evaluate_script("undefined")).to eq(nil)

      expect(@session.evaluate_script("3;")).to eq(3)
      expect(@session.evaluate_script("31337")).to eq(31_337)
      expect(@session.evaluate_script(%("string"))).to eq("string")
      expect(@session.evaluate_script(%({foo: "bar"}))).to eq("foo" => "bar")

      expect(@session.evaluate_script("new Object")).to eq({})
      expect(@session.evaluate_script("new Date(2012, 0).toDateString()")).to eq("Sun Jan 01 2012")
      expect(@session.evaluate_script("new Object({a: 1})")).to eq({ "a" => 1 })
      expect(@session.evaluate_script("new Array")).to eq([])
      expect(@session.evaluate_script("new Function")).to eq({})

      expect { @session.evaluate_script(%(throw "smth")) }.to raise_error(Ferrum::JavaScriptError)
    end

    it "returns cyclic structures without raising" do
      code = <<-JS
        (function() {
          var a = {};
          var b = {};
          var c = {};
          c.a = a;
          a.a = a;
          a.b = b;
          a.c = c;
          return a;
        })()
      JS

      cyclic = Ferrum::CyclicObject.instance
      expect(@session.evaluate_script(code)).to eq("a" => cyclic, "b" => {}, "c" => { "a" => cyclic })
    end
  end

  describe "#evaluate_async_script" do
    it "returns values properly" do
      @session.using_wait_time(5) do
        expect(@session.driver.evaluate_async_script("arguments[0](null)")).to be_nil
        expect(@session.driver.evaluate_async_script("arguments[0](false)")).to be false
        expect(@session.driver.evaluate_async_script("arguments[0](true)")).to be true
        expect(@session.driver.evaluate_async_script(%(arguments[0]({foo: "bar"})))).to eq("foo" => "bar")
      end
    end

    it "times out" do
      @session.using_wait_time(1) do
        expect do
          @session.driver.evaluate_async_script <<~JS
            var callback=arguments[0]; setTimeout(function(){callback(true)}, 4000)
          JS
        end.to raise_error Ferrum::ScriptTimeoutError
      end
    end

    it "waits for the session's wait time in threadsafe mode" do
      Capybara::SpecHelper.reset_threadsafe(bool: true, session: @session)
      Capybara.default_max_wait_time = 1
      @session.config.default_max_wait_time = 3

      expect(@session.driver.evaluate_async_script("setTimeout(() => arguments[0](true), 2000)")).to be(true)
    ensure
      Capybara::SpecHelper.reset_threadsafe(bool: false, session: @session)
    end
  end

  describe "#execute_script" do
    it "executes multiple lines of javascript" do
      @driver.execute_script <<-JS
        var a = 1
        var b = 2
        window.result = a + b
      JS
      expect(@driver.evaluate_script("window.result")).to eq(3)
    end
  end

  describe "#active_element" do
    it "returns the focused element" do
      @session.visit("/cuprite/send_keys")

      input = @session.find_field("empty_input")
      input.execute_script("this.focus()")

      expect(@session.active_element).to eq(input)
    end
  end

  describe "#send_keys" do
    it "sends keys to the focused element" do
      @session.visit("/cuprite/send_keys")

      @session.find_field("empty_input").execute_script("this.focus()")
      @session.find_field("empty_input").execute_script <<~JS
        this.addEventListener("click", () => window.clickedBeforeFocus = true)
      JS

      expect(@session).to have_field("empty_input", focused: true)

      @session.send_keys(:tab)

      expect(@session).to have_field("empty_input", focused: false)
        .and(have_field("filled_input", focused: true))
      expect(@session.evaluate_script("window.clickedBeforeFocus")).to be_nil
    end
  end

  describe "#save_screenshot" do
    let(:format) { :png }
    let(:file) { "#{PROJECT_ROOT}/spec/tmp/screenshot.#{format}" }

    after do
      FileUtils.rm_f("#{PROJECT_ROOT}/spec/tmp/screenshot.pdf")
      FileUtils.rm_f("#{PROJECT_ROOT}/spec/tmp/screenshot.png")
    end

    it "supports rendering the page" do
      @session.visit("/")

      @driver.save_screenshot(file)

      expect(File.exist?(file)).to be true
    end

    it "supports rendering the page with a nonstring path" do
      @session.visit("/")

      @driver.save_screenshot(Pathname(file))

      expect(File.exist?(file)).to be true
    end

    it "supports rendering the page to file without extension when format is specified" do
      file = "#{PROJECT_ROOT}/spec/tmp/screenshot"
      @session.visit("/")

      @driver.save_screenshot(file, format: "jpg")

      expect(File.exist?(file)).to be true
    ensure
      FileUtils.rm_f(file)
    end

    context "with :paper_width and :paper_height" do
      let(:format) { :pdf }

      it "changes pdf size" do
        @session.visit("/cuprite/long_page")

        @driver.save_screenshot(file, paper_width: 6, paper_height: 12)

        reader = PDF::Reader.new(file)
        reader.pages.each do |page|
          bbox = page.attributes[:MediaBox]
          width = (bbox[2] - bbox[0]) / 72
          height = (bbox[3] - bbox[1]) / 72
          expect(width).to eq(6)
          expect(height).to eq(12)
        end
      end
    end
  end

  describe "#maximize_window" do
    it "maximizes to 1366x768 by default" do
      @session.visit("/")
      @session.current_window.maximize
      expect(@session.current_window.size).to eq([1366, 768])
    end

    context "with :screen_size" do
      let(:session) { Capybara::Session.new(:cuprite_with_screen_size, TestApp) }

      before do
        Capybara.register_driver(:cuprite_with_screen_size) do |app|
          Capybara::Cuprite::Driver.new(app, screen_size: [1600, 1200])
        end
      end

      after { session.driver.quit }

      it "maximizes to the given screen size" do
        session.visit("/")
        session.current_window.maximize
        expect(session.current_window.size).to eq([1600, 1200])
      end
    end
  end

  describe "#resize_window_to" do
    it "resizes the viewport" do
      @session.visit("/")
      @session.current_window.resize_to(200, 400)
      expect(
        @driver.evaluate_script("[window.innerWidth, window.innerHeight]")
      ).to eq([200, 400])
    end

    it "keeps the pointer type set with --blink-settings" do
      Capybara.register_driver :cuprite_with_blink_settings do |app|
        Capybara::Cuprite::Driver.new(
          app, browser_options: { "blink-settings" => "primaryPointerType=2,availablePointerTypes=2" }
        )
      end
      session = Capybara::Session.new(:cuprite_with_blink_settings, TestApp)
      session.visit("/")

      expect do
        session.current_window.resize_to(800, 600)
      end.not_to(change { session.evaluate_script("matchMedia('(pointer: coarse)').matches") }.from(true))
    ensure
      session&.driver&.quit
    end

    it "resizes popup windows" do
      @session.visit "/"

      popup1 = @session.window_opened_by do
        @session.execute_script <<-JS
          window.open("/cuprite/simple", "popup1")
        JS
      end

      popup2 = @session.window_opened_by do
        @session.execute_script <<-JS
          window.open("/cuprite/simple", "popup2")
        JS
      end

      popup1.resize_to(100, 200)
      popup2.resize_to(200, 100)

      expect(popup1.size).to eq([100, 200])
      expect(popup2.size).to eq([200, 100])
    end
  end

  describe "#window_handles" do
    it "returns the open windows" do
      @session.visit "/"

      @session.execute_script <<-JS
        window.open("/cuprite/simple", "popup")
      JS

      sleep 0.1

      expect(@driver.window_handles.size).to eq(2)

      popup2 = @session.window_opened_by do
        @session.execute_script <<-JS
          window.open("/cuprite/simple", "popup2")
        JS
      end

      expect(@driver.window_handles.size).to eq(3)

      @session.within_window(popup2) do
        expect(@session.html).to include("Test")
        # Browser isn't dead, current page after executing JS closes connection
        # and we don't have a chance to push response to the Queue. Since the
        # queue and websocket are closed and response is nil the proper guess
        # would be that browser is dead, but in fact the page is dead and
        # browser is fully alive.
        begin
          @session.execute_script("window.close()")
        rescue StandardError
          Ferrum::DeadBrowserError
        end
      end

      sleep 0.1

      expect(@driver.window_handles.size).to eq(2)
    end

    it "leaves out web workers" do
      @session.visit "/cuprite/with_worker"

      expect(@driver.window_handles.size).to eq(1)

      new_window = @session.window_opened_by { @session.click_link "Open tab" }

      expect(@driver.window_handles).to contain_exactly(@session.current_window.handle, new_window.handle)
      @session.within_window(new_window) { expect(@session).to have_link("Open tab") }
    end
  end

  describe "#open_new_window" do
    it "opens a window that inherits the size" do
      @session.visit "/"
      @session.current_window.resize_to(1200, 800)
      new_tab = @session.open_new_window
      expect(new_tab.size).to eq [1200, 800]
    end

    it "opens a window that inherits url_blacklist" do
      @driver.browser.url_blacklist = /unwanted/
      @session.visit "/"
      new_tab = @session.open_new_window
      @session.within_window(new_tab) do
        @session.visit "/cuprite/url_blacklist"
        expect(@session).to have_content("We are loading some unwanted action here")
        @session.within_frame "framename" do
          expect(@session.html).not_to include("We shouldn't see this.")
        end
      end
    end

    it "opens a window that inherits url_whitelist" do
      @session.visit "/"
      @driver.browser.url_whitelist = [/url_whitelist/, %r{/cuprite/wanted}]
      new_tab = @session.open_new_window
      @session.within_window(new_tab) do
        @session.visit "/cuprite/url_whitelist"

        expect(@session).to have_content("We are loading some wanted action here")
        @session.within_frame "framename" do
          expect(@session).to have_content("We should see this.")
        end
        @session.within_frame "unwantedframe" do
          # make sure non whitelisted urls are blocked
          expect(@session).not_to have_content("We shouldn't see this.")
        end
      end
    end
  end

  describe "#switch_to_window" do
    it "waits for the window to load" do
      @session.visit "/"

      popup = @session.window_opened_by do
        @session.execute_script <<-JS
          window.open("/cuprite/slow", "popup")
        JS
      end

      @session.within_window(popup) do
        expect(@session.html).to include("slow page")
      end
      popup.close
    end

    it "switches to a second window of the same name" do
      @session.visit "/"

      popup = @session.window_opened_by do
        @session.execute_script <<-JS
          window.open("/cuprite/simple", "popup")
        JS
      end
      @session.within_window(popup) do
        expect(@session.html).to include("Test")
      end
      popup.close

      sleep 0.5 # https://github.com/ChromeDevTools/devtools-protocol/issues/145

      same = @session.window_opened_by do
        @session.execute_script <<-JS
          window.open("/cuprite/simple", "popup")
        JS
      end
      @session.within_window(same) do
        expect(@session.html).to include("Test")
      end
      same.close
    end

    it "activates the target when switching back to a window" do
      @session.visit "/"
      original = @session.current_window

      popup = @session.window_opened_by do
        @session.execute_script <<-JS
          window.open("/cuprite/simple", "popup")
        JS
      end

      @session.within_window(popup) do
        expect(@session.evaluate_script("document.visibilityState")).to eq("visible")
      end

      @session.switch_to_window(original)
      expect(@session.evaluate_script("document.visibilityState")).to eq("visible")

      popup.close
    end

    context "with headers", skip: true do
      it "persists headers across popup windows" do
        @driver.browser.headers.set(
          "Cookie" => "foo=bar",
          "Host" => "foo.com",
          "User-Agent" => "foo"
        )
        @session.visit("/cuprite/popup_headers")
        @session.click_link "pop up"
        @session.switch_to_window @session.windows.last
        expect(@driver.html).to include("USER_AGENT: foo")
        expect(@driver.html).to include("COOKIE: foo=bar")
        expect(@driver.html).to include("HOST: foo.com")
      end

      it "sets headers in existing windows" do
        @session.open_new_window
        @driver.browser.headers.set(
          "Cookie" => "foo=bar",
          "Host" => "foo.com",
          "User-Agent" => "foo"
        )
        @session.visit("/cuprite/headers")
        expect(@driver.html).to include("USER_AGENT: foo")
        expect(@driver.html).to include("COOKIE: foo=bar")
        expect(@driver.html).to include("HOST: foo.com")

        @session.switch_to_window @session.windows.last
        @session.visit("/cuprite/headers")
        expect(@driver.html).to include("USER_AGENT: foo")
        expect(@driver.html).to include("COOKIE: foo=bar")
        expect(@driver.html).to include("HOST: foo.com")
      end

      it "keeps temporary headers local to the current window" do
        @session.open_new_window
        @driver.browser.headers.add({ "X-Custom-Header" => "1" }, permanent: false)

        @session.switch_to_window @session.windows.last
        @session.visit("/cuprite/headers")
        expect(@driver.html).not_to include("X_CUSTOM_HEADER: 1")

        @session.switch_to_window @session.windows.first
        @session.visit("/cuprite/headers")
        expect(@driver.html).to include("X_CUSTOM_HEADER: 1")
      end

      it "does not mix temporary headers with permanent ones when propagating to other windows" do
        @session.open_new_window
        @driver.browser.headers.add({ "X-Custom-Header" => "1" }, permanent: false)
        @driver.browser.headers.add({ "Host" => "foo.com" })

        @session.switch_to_window @session.windows.last
        @session.visit("/cuprite/headers")
        expect(@driver.html).to include("HOST: foo.com")
        expect(@driver.html).not_to include("X_CUSTOM_HEADER: 1")

        @session.switch_to_window @session.windows.first
        @session.visit("/cuprite/headers")
        expect(@driver.html).to include("HOST: foo.com")
        expect(@driver.html).to include("X_CUSTOM_HEADER: 1")
      end

      it "does not propagate temporary headers to new windows" do
        @session.visit "/"
        @driver.browser.headers.add({ "X-Custom-Header" => "1" }, permanent: false)
        @session.open_new_window

        @session.switch_to_window @session.windows.last
        @session.visit("/cuprite/headers")
        expect(@driver.html).not_to include("X_CUSTOM_HEADER: 1")

        @session.switch_to_window @session.windows.first
        @session.visit("/cuprite/headers")
        expect(@driver.html).to include("X_CUSTOM_HEADER: 1")
      end
    end
  end

  describe "#switch_to_frame" do
    it "switches to a frame selected by index" do
      @session.visit "/cuprite/frames"

      @session.within_frame 0 do
        expect(@session.driver.frame_url).to end_with("/cuprite/slow")
      end
    end

    it "switches to a frame selected by element" do
      @session.visit "/cuprite/frames"
      frame = @session.find(:css, "iframe[name]")

      @session.within_frame(frame) do
        expect(@session.driver.frame_url).to end_with("/cuprite/slow")
      end
    end

    it "switches to a frame selected by driver node" do
      @session.visit "/cuprite/frames"
      frame = @session.driver.find_css("iframe[name]").first

      @session.driver.switch_to_frame(frame)
      expect(@session.driver.frame_url).to end_with("/cuprite/slow")
    ensure
      @session.driver.switch_to_frame(:top)
    end

    it "rejects driver nodes without frame ids" do
      @session.visit "/cuprite/simple"
      node = @session.driver.find_css("body").first

      expect do
        @session.driver.switch_to_frame(node)
      end.to raise_error(ArgumentError, /Unable to switch to frame/)

      expect(@session.driver.frame_url).to end_with("/cuprite/simple")
    end

    it "switches to a frame without name or id" do
      @session.visit "/cuprite/frames"
      frame = @session.find(:css, "iframe:not([name]):not([id])")

      @session.within_frame(frame) do
        expect(@session.driver.frame_url).to end_with("/cuprite/headers")
      end
    end

    it "switches to a frame with id but no name" do
      @session.visit "/cuprite/frames"
      frame = @session.find(:css, "iframe[id]:not([name])")

      @session.within_frame(frame) do
        expect(@session.driver.frame_url).to end_with("/cuprite/get_cookie")
      end
    end

    it "waits for the frame to load" do
      @session.visit "/"

      @session.execute_script <<-JS
        document.body.innerHTML += "<iframe src='/cuprite/slow' name='frame'>"
      JS

      @session.within_frame "frame" do
        expect(@session.driver.frame_url).to end_with("/cuprite/slow")
        expect(@session.html).to include("slow page")
      end
      expect(URI.parse(@session.driver.frame_url).path).to eq("/")
    end

    it "waits for the cross-domain frame to load" do
      @session.visit "/cuprite/frames"
      expect(@session.current_path).to eq("/cuprite/frames")

      @session.within_frame "frame" do
        expect(@session.driver.frame_url).to end_with("/cuprite/slow")
        expect(@session.body).to include("slow page")
      end

      expect(@session.driver.frame_url).to end_with("/cuprite/frames")
    end

    it "does not wait forever for the frame to load" do
      @session.visit "/"

      expect do
        @session.within_frame("omg", &:itself)
      end.to(raise_error do |e|
        expect(e).to be_a(Capybara::ElementNotFound)
      end)
    end

    it "generates no javascript errors when switching into a frame" do
      @session.driver.browser.evaluate_on_new_document(
        "window.errors ||= []; window.onerror = function(msg) { window.errors += msg; };"
      )

      @session.visit "/cuprite/frames"
      @session.within_frame(0) do
        expect(@session.evaluate_script("window.errors")).to be_empty
      end
      expect(@session.evaluate_script("window.errors")).to be_empty
    end

    it "doesn't hang on an about:blank frame without a document" do
      @session.visit "/"
      @session.execute_script <<-JS
        document.body.innerHTML += "<iframe src='about:blank' name='frame'>"
      JS
      @session.within_frame "frame" do
        expect(@session).to have_no_xpath("/html/body/*")
      end
    end

    it "doesn't hang on an about:blank frame built by JS" do
      @session.visit "/"
      @session.execute_script <<-JS
        document.body.innerHTML += "<iframe src='about:blank' name='frame'>";
        var iframeDocument = document.querySelector("iframe[name='frame']").contentWindow.document;
        var content = "<html><body><p>Hello Frame</p></body></html>";
        iframeDocument.open("text/html", "replace");
        iframeDocument.write(content);
        iframeDocument.close();
      JS

      @session.within_frame "frame" do
        expect(@session).to have_content("Hello Frame")
      end
    end

    it "doesn't hang on a frame with srcdoc" do
      @session.visit "/"
      @session.execute_script <<-JS
        document.body.innerHTML += "<iframe srcdoc='<p>Hello Frame</p>' name='frame'>"
      JS

      @session.within_frame "frame" do
        expect(@session).to have_content("Hello Frame", wait: false)
      end
    end

    it "doesn't hang on a frame without src filled by JS" do
      @session.visit "/"
      @session.execute_script <<-JS
        document.body.innerHTML += "<iframe id='frame' name='frame'>"
      JS
      @session.execute_script <<-JS
        var iframeDocument = document.querySelector("#frame").contentWindow.document;
        var content = "<html><body><p>Hello Frame</p></body></html>";
        iframeDocument.open("text/html", "replace");
        iframeDocument.write(content);
        iframeDocument.close();
      JS

      @session.within_frame "frame" do
        expect(@session).to have_content("Hello Frame", wait: false)
      end
    end
  end

  describe "#accept_modal" do
    it "matches on partial strings" do
      @session.visit "/cuprite/with_js"
      expect do
        @session.accept_confirm "[reg.exp] (chara©+er$)" do
          @session.click_link("Open for match")
        end
      end.not_to raise_error
      expect(@session).to have_xpath("//a[@id='open-match' and @confirmed='true']")
    end

    it "matches on regular expressions" do
      @session.visit "/cuprite/with_js"
      expect do
        @session.accept_confirm(/^.t.ext.*\[\w{3}\.\w{3}\]/i) do
          @session.click_link("Open for match")
        end
      end.not_to raise_error
      expect(@session).to have_xpath("//a[@id='open-match' and @confirmed='true']")
    end

    it "works with nested modals" do
      @session.visit "/cuprite/with_js"
      expect do
        @session.dismiss_confirm "Are you really sure?" do
          @session.accept_confirm "Are you sure?" do
            @session.click_link("Open check twice")
          end
        end
      end.not_to raise_error
      expect(@session).to have_xpath("//a[@id='open-twice' and @confirmed='false']")
    end

    it "works with second window" do
      @session.visit "/"

      popup = @session.window_opened_by do
        @session.execute_script <<-JS
          window.open("/cuprite/with_js", "popup")
        JS
      end

      @session.within_window(popup) do
        expect do
          @session.accept_confirm do
            @session.click_link("Open for match")
          end
          expect(@session).to have_xpath("//a[@id='open-match' and @confirmed='true']")
        end.not_to raise_error
      end
      popup.close
    end
  end
end

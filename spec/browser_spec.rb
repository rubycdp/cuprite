# frozen_string_literal: true

describe Capybara::Cuprite::Browser do
  let(:mobile) { false }

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

  describe "#command" do
    it "restarts the browser when it dies during a command" do
      driver = Capybara::Cuprite::Driver.new(nil)
      expect { driver.browser.crash }.to raise_error(Ferrum::DeadBrowserError)
      driver.visit(session_url("/"))
      expect(driver.html).to include("Hello world")
    end
  end

  describe "#restart" do
    it "starts over with empty network traffic" do
      @session.visit("/cuprite/with_js")
      expect(@driver.browser.network.traffic.length).to eq(4)

      @driver.browser.restart

      @session.visit("/cuprite/with_js")
      expect(@driver.browser.network.traffic.length).to eq(4)
    end
  end
end

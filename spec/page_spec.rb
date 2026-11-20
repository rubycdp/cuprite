# frozen_string_literal: true

describe Capybara::Cuprite::Page do
  around do |example|
    @session = TestSessions::Cuprite
    @driver = @session.driver
    example.run
  ensure
    @driver.reset!
  end

  def session_url(path)
    server = @session.server
    "http://#{server.host}:#{server.port}#{path}"
  end

  describe "#go_to" do
    it "passes the referrer to the navigation" do
      @driver.browser.go_to(session_url("/cuprite/headers"), referrer: "http://example.com/")

      expect(@driver.html).to include("REFERER: http://example.com/")
    end
  end
end

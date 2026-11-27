# frozen_string_literal: true

describe Capybara::Cuprite::Driver::Deprecations do
  around do |example|
    @driver = Capybara::Cuprite::Driver.new(nil)
    example.run
  ensure
    @driver.quit
  end

  describe ".extend_browser" do
    def expect_deprecated(name, &)
      message = "page.driver.browser.#{name} is deprecated and will be removed in 1.0, use page.driver.#{name} instead"
      expect(&).to output(/#{Regexp.escape(message)}/).to_stderr
    end

    it "forwards url_blocklist= on the browser to the driver with a warning" do
      expect_deprecated("url_blocklist=") { @driver.browser.url_blocklist = /unwanted/ }
      expect(@driver.url_blocklist).to eq([/unwanted/])
    end

    it "forwards url_allowlist on the browser to the driver with a warning" do
      @driver.url_allowlist = /wanted/

      expect_deprecated("url_allowlist") { expect(@driver.browser.url_allowlist).to eq([/wanted/]) }
    end

    it "forwards raise_on_unhandled_modal= on the browser to the driver with a warning" do
      expect_deprecated("raise_on_unhandled_modal=") { @driver.browser.raise_on_unhandled_modal = true }
      expect(@driver.raise_on_unhandled_modal).to be(true)
    end
  end
end

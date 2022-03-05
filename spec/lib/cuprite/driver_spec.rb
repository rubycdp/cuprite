# frozen_string_literal: true

describe Capybara::Cuprite::Driver do
  describe "#reset!" do
    it "aliases the url_blacklist option, for backwards compatibility" do
      driver = described_class.new(nil, { url_blacklist: ["unwanted"] })
      driver.reset!

      expect(driver.browser.url_blocklist).to contain_exactly(/unwanted/i)
    end

    it "aliases the url_whitelist option, for backwards compatibility" do
      driver = described_class.new(nil, { url_whitelist: ["allowed"] })
      driver.reset!

      expect(driver.browser.url_allowlist).to contain_exactly(/allowed/i)
    end
  end
end

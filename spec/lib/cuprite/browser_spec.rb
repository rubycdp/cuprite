# frozen_string_literal: true

describe Capybara::Cuprite::Browser do
  describe "url_blacklist option" do
    it "is an alias of url_blocklist, for backwards compatibility" do
      browser = described_class.new(url_blacklist: ["example"])

      expect([browser.url_blocklist, browser.url_blacklist]).to all contain_exactly(/example/i)
    end
  end

  describe "url_whitelist option" do
    it "is an alias of url_allowlist, for backwards compatibility" do
      browser = described_class.new(url_whitelist: ["example"])

      expect([browser.url_allowlist, browser.url_whitelist]).to all contain_exactly(/example/i)
    end
  end

  describe "#url_blacklist=" do
    it "is an alias of #url_blocklist=, for backwards compatibility" do
      browser = described_class.new
      browser.url_blacklist = ["example"]

      expect(browser.url_blocklist).to contain_exactly(/example/i)
    end
  end

  describe "#url_whitelist=" do
    it "is an alias of #url_allowlist=, for backwards compatibility" do
      browser = described_class.new
      browser.url_whitelist = ["example"]

      expect(browser.url_allowlist).to contain_exactly(/example/i)
    end
  end
end

# frozen_string_literal: true

describe Capybara::Cuprite::Driver do
  describe ".new" do
    it "sets the remote-allow-origins option" do
      driver = described_class.new(nil)

      expect(driver.browser.options.to_h[:browser_options]).to include("remote-allow-origins": "*")
    end

    it "sets the disable-web-security option" do
      driver = described_class.new(nil)

      expect(driver.browser.options.to_h[:browser_options]).to include("disable-web-security": nil)
    end

    it "defaults :save_path to the Capybara save path" do
      driver = with_capybara_save_path("/tmp/capybara-save-path") do
        described_class.new(nil)
      end

      expect(driver.browser.options.to_h).to include(save_path: "/tmp/capybara-save-path")
    end

    it "takes a custom :save_path" do
      custom_path = Dir.mktmpdir

      driver = with_capybara_save_path("/tmp/capybara-save-path") do
        described_class.new(nil, { save_path: custom_path })
      end

      expect(driver.browser.options.to_h).to include(save_path: custom_path)
    end
  end

  describe "#browser" do
    it "raises for both :url_blacklist and :url_whitelist" do
      driver = described_class.new(nil, { url_blacklist: /unwanted/, url_whitelist: /wanted/ })

      expect { driver.browser }.to raise_error(ArgumentError, "You can't use whitelist along with blacklist")
    end
  end

  describe "#reset!" do
    it "restores the url_blacklist set at runtime" do
      driver = described_class.new(nil, { url_blacklist: /unwanted/ })
      driver.url_blacklist = /other/

      driver.reset!

      expect(driver.url_blacklist).to eq([/unwanted/])
    ensure
      driver&.quit
    end

    it "keeps raise_on_unhandled_modal" do
      driver = described_class.new(nil, { raise_on_unhandled_modal: true })

      driver.browser

      expect { driver.reset! }.not_to(change { driver.raise_on_unhandled_modal })
      expect(driver.raise_on_unhandled_modal).to eq(true)
    end

    it "drops the cached page even when the browser fails to reset" do
      driver = described_class.new(nil)
      driver.visit("about:blank")
      allow(driver.browser.contexts).to receive(:reset).and_wrap_original do |reset|
        reset.call
        raise Ferrum::TimeoutError
      end

      expect { driver.reset! }.to raise_error(Ferrum::TimeoutError)
      expect { driver.visit("about:blank") }.not_to raise_error
    ensure
      driver&.quit
    end

    it "doesn't launch a browser when none has started" do
      driver = described_class.new(nil)
      allow(Ferrum::Browser).to receive(:new).and_raise(Ferrum::ProcessTimeoutError.new(10, ""))

      expect { driver.visit("about:blank") }.to raise_error(Ferrum::ProcessTimeoutError)
      expect { driver.reset! }.not_to raise_error
      expect(Ferrum::Browser).to have_received(:new).once
    end
  end

  describe "#quit" do
    it "doesn't launch a browser when none has started" do
      driver = described_class.new(nil)
      allow(Ferrum::Browser).to receive(:new).and_raise(Ferrum::ProcessTimeoutError.new(10, ""))

      expect { driver.quit }.not_to raise_error
      expect(Ferrum::Browser).not_to have_received(:new)
    end
  end

  private

  def with_capybara_save_path(path)
    original_capybara_save_path = Capybara.save_path
    Capybara.save_path = path
    yield
  ensure
    Capybara.save_path = original_capybara_save_path
  end
end

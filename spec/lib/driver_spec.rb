# frozen_string_literal: true

describe Capybara::Cuprite::Driver do
  describe "options" do
    it "sets the remote-allow-origins option" do
      driver = described_class.new(nil)

      expect(driver.browser.options.to_h[:browser_options]).to include("remote-allow-origins": "*")
    end

    it "sets the disable-web-security option" do
      driver = described_class.new(nil)

      expect(driver.browser.options.to_h[:browser_options]).to include("disable-web-security": nil)
    end
  end

  describe "raise_on_unhandled_modal configuration" do
    it "survives resetting the driver between examples" do
      driver = described_class.new(nil, { raise_on_unhandled_modal: true })

      driver.browser

      expect { driver.reset! }.not_to(change { driver.browser.raise_on_unhandled_modal })
      expect(driver.browser.raise_on_unhandled_modal).to eq(true)
    end
  end

  describe "#reset!" do
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
      allow(Capybara::Cuprite::Browser).to receive(:new).and_raise(Ferrum::ProcessTimeoutError.new(10, ""))

      expect { driver.visit("about:blank") }.to raise_error(Ferrum::ProcessTimeoutError)
      expect { driver.reset! }.not_to raise_error
      expect(Capybara::Cuprite::Browser).to have_received(:new).once
    end
  end

  describe "#quit" do
    it "doesn't launch a browser when none has started" do
      driver = described_class.new(nil)
      allow(Capybara::Cuprite::Browser).to receive(:new).and_raise(Ferrum::ProcessTimeoutError.new(10, ""))

      expect { driver.quit }.not_to raise_error
      expect(Capybara::Cuprite::Browser).not_to have_received(:new)
    end
  end

  describe "save_path configuration" do
    it "defaults to the Capybara save path" do
      driver = with_capybara_save_path("/tmp/capybara-save-path") do
        described_class.new(nil)
      end

      expect(driver.browser.options.to_h).to include(save_path: "/tmp/capybara-save-path")
    end

    it "allows a custom path to be specified" do
      custom_path = Dir.mktmpdir

      driver = with_capybara_save_path("/tmp/capybara-save-path") do
        described_class.new(nil, { save_path: custom_path })
      end

      expect(driver.browser.options.to_h).to include(save_path: custom_path)
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

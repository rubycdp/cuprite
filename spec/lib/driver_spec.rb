# frozen_string_literal: true

describe Capybara::Cuprite::Driver do
  describe "options" do
    it "sets the remote-allow-origins option" do
      driver = described_class.new(nil)

      expect(driver.browser.options.to_h[:browser_options]).to include("remote-allow-origins": "*")
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

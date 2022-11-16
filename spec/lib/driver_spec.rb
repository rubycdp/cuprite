# frozen_string_literal: true

describe Capybara::Cuprite::Driver do
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

# frozen_string_literal: true

describe Capybara::Cuprite::Driver do
  describe "options" do
    it "sets the remote-allow-origins option" do
      driver = described_class.new(nil)

      expect(driver.browser.options.to_h[:browser_options]).to include("remote-allow-origins": "*")
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

  describe "debug_url" do
    it "parses the devtools frontend url correctly" do
      driver = described_class.new(nil, { port: 12_345 })
      driver.browser # initialize browser before stubbing Net::HTTP as it also calls it
      uri = instance_double(URI)

      allow(driver).to receive(:URI).with("http://127.0.0.1:12345/json").and_return(uri)
      allow(Net::HTTP).to receive(:get).with(uri).and_return(%([{"devtoolsFrontendUrl":"/works"}]))

      expect(driver.debug_url).to eq("http://127.0.0.1:12345/works")
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

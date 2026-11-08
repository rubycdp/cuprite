# frozen_string_literal: true

describe Capybara::Cuprite::Browser::Extensions do
  let(:mobile) { false }

  around do |example|
    @session = mobile ? TestSessions::CupriteMobile : TestSessions::Cuprite
    @driver = @session.driver
    example.run
  ensure
    @driver.reset!
  end

  describe "#url_blacklist=" do
    it "blocks unwanted urls" do
      @driver.browser.url_blacklist = /unwanted/

      @session.visit "/cuprite/url_blacklist"

      expect(@session.status_code).to eq(200)
      expect(@session).to have_content("We are loading some unwanted action here")
      @session.within_frame "framename" do
        expect(@session.html).not_to include("We shouldn't see this.")
      end
    end

    it "blocks urls matching a regexp" do
      @driver.browser.url_blacklist = /.*wanted/

      @session.visit "/cuprite/url_whitelist"

      expect(@session.status_code).to eq(200)
      expect(@session).to have_content("We are loading some wanted action here")
      @session.within_frame "framename" do
        expect(@session).not_to have_content("We should see this.")
      end
      @session.within_frame "unwantedframe" do
        expect(@session).not_to have_content("We shouldn't see this.")
      end
    end

    it "keeps blocking urls from the driver option after reset!" do
      Capybara.register_driver :cuprite_blacklist do |app|
        Capybara::Cuprite::Driver.new(app, @driver.options.merge(url_blacklist: /unwanted/))
      end

      session = Capybara::Session.new(:cuprite_blacklist, @session.app)

      session.visit "/cuprite/url_blacklist"
      expect(session).to have_content("We are loading some unwanted action here")
      session.within_frame "framename" do
        expect(session.html).not_to include("We shouldn't see this.")
      end

      session.reset!

      session.visit "/cuprite/url_blacklist"
      expect(session).to have_content("We are loading some unwanted action here")
      session.within_frame "framename" do
        expect(session.html).not_to include("We shouldn't see this.")
      end
    end

    it "keeps blocking urls from the url_blocklist driver option after reset!" do
      Capybara.register_driver :cuprite_blocklist do |app|
        Capybara::Cuprite::Driver.new(app, @driver.options.merge(url_blocklist: /unwanted/))
      end

      session = Capybara::Session.new(:cuprite_blocklist, @session.app)

      session.visit "/cuprite/url_blacklist"
      expect(session).to have_content("We are loading some unwanted action here")
      session.within_frame "framename" do
        expect(session.html).not_to include("We shouldn't see this.")
      end

      session.reset!

      session.visit "/cuprite/url_blacklist"
      expect(session).to have_content("We are loading some unwanted action here")
      session.within_frame "framename" do
        expect(session.html).not_to include("We shouldn't see this.")
      end
    end
  end

  describe "#url_whitelist=" do
    it "allows whitelisted urls" do
      @driver.browser.url_whitelist = [/url_whitelist/, %r{/wanted}]

      @session.visit "/cuprite/url_whitelist"

      expect(@session.status_code).to eq(200)
      expect(@session).to have_content("We are loading some wanted action here")
      @session.within_frame "framename" do
        expect(@session).to have_content("We should see this.")
      end
      @session.within_frame "unwantedframe" do
        expect(@session).not_to have_content("We shouldn't see this.")
      end
    end

    it "allows urls matching a regexp" do
      @driver.browser.url_whitelist = [/url_whitelist/, %r{/.*wanted}]

      @session.visit "/cuprite/url_whitelist"

      expect(@session.status_code).to eq(200)
      expect(@session).to have_content("We are loading some wanted action here")
      @session.within_frame "framename" do
        expect(@session).to have_content("We should see this.")
      end
      @session.within_frame "unwantedframe" do
        expect(@session).to have_content("We shouldn't see this.")
      end
    end

    it "raises when a blacklist is also set" do
      @driver.browser.url_whitelist = /url_whitelist/
      expect { @driver.browser.url_blacklist = /url_whitelist/ }
        .to raise_error(ArgumentError, "You can't use blacklist along with whitelist")
    end

    it "allows urls when the whitelist is empty" do
      @driver.browser.url_whitelist = []

      @session.visit "/cuprite/url_whitelist"

      expect(@session.status_code).to eq(200)
      expect(@session).to have_content("We are loading some wanted action here")
      @session.within_frame "framename" do
        expect(@session).to have_content("We should see this.")
      end
    end

    it "keeps allowing urls from the driver option after reset!" do
      Capybara.register_driver :cuprite_whitelist do |app|
        Capybara::Cuprite::Driver.new(app,
                                      @driver.options.merge(url_whitelist: [/url_whitelist/, %r{/cuprite/wanted}]))
      end

      session = Capybara::Session.new(:cuprite_whitelist, @session.app)

      session.visit "/cuprite/url_whitelist"
      expect(session).to have_content("We are loading some wanted action here")
      session.within_frame "framename" do
        expect(session).to have_content("We should see this.")
      end

      session.within_frame "unwantedframe" do
        # make sure non whitelisted urls are blocked
        expect(session).not_to have_content("We shouldn't see this.")
      end

      session.reset!

      session.visit "/cuprite/url_whitelist"
      expect(session).to have_content("We are loading some wanted action here")
      session.within_frame "framename" do
        expect(session).to have_content("We should see this.")
      end
      session.within_frame "unwantedframe" do
        # make sure non whitelisted urls are blocked
        expect(session).not_to have_content("We shouldn't see this.")
      end
    end

    it "keeps allowing urls from the url_allowlist driver option after reset!" do
      Capybara.register_driver :cuprite_allowlist do |app|
        Capybara::Cuprite::Driver.new(app,
                                      @driver.options.merge(url_allowlist: [/url_whitelist/, %r{/cuprite/wanted}]))
      end

      session = Capybara::Session.new(:cuprite_allowlist, @session.app)

      session.visit "/cuprite/url_whitelist"
      expect(session).to have_content("We are loading some wanted action here")
      session.within_frame "framename" do
        expect(session).to have_content("We should see this.")
      end
      session.within_frame "unwantedframe" do
        expect(session).not_to have_content("We shouldn't see this.")
      end

      session.reset!

      session.visit "/cuprite/url_whitelist"
      expect(session).to have_content("We are loading some wanted action here")
      session.within_frame "framename" do
        expect(session).to have_content("We should see this.")
      end
      session.within_frame "unwantedframe" do
        expect(session).not_to have_content("We shouldn't see this.")
      end
    end
  end

  describe "#raise_on_unhandled_modal=" do
    it "accepts an unhandled modal with a warning by default" do
      @session.visit "/cuprite/with_js"
      expect(@session.driver.browser.page)
        .to receive(:warn).with(
          "Modal window with text `{T}ext \\w|th [reg.exp] (chara©+er$)?` has been opened, " \
          "but you didn't wrap your code into (`accept_prompt` | `dismiss_prompt` | `accept_confirm` " \
          "| `dismiss_confirm` | `accept_alert`), accepting by default"
        )

      expect { @session.click_link("Open for match") }.not_to raise_error

      expect(@session).to have_xpath("//a[@id='open-match' and @confirmed='true']")
    end

    it "raises on an unhandled modal when true" do
      @session.driver.browser.raise_on_unhandled_modal = true

      @session.visit "/cuprite/with_js"

      expect { @session.click_link("Open for match") }.to raise_error(
        Capybara::Cuprite::UnhandledModalError,
        "Modal window with text `{T}ext \\w|th [reg.exp] (chara©+er$)?` has been opened, " \
        "but you didn't wrap your code into (`accept_prompt` | `dismiss_prompt` | `accept_confirm` " \
        "| `dismiss_confirm` | `accept_alert`), accepting by default"
      )
    end
  end
end

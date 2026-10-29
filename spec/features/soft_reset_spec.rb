# frozen_string_literal: true

module Capybara
  module Cuprite
    describe Driver do
      context "with reset: :soft" do
        around do |example|
          @session = TestSessions::CupriteSoftReset
          @driver = @session.driver
          example.run
        ensure
          @session.reset!
        end

        it "keeps the HTTP cache" do
          @session.visit("/cuprite/cacheable")
          expect(@driver.browser.network.traffic.last.response.params.dig("response", "fromDiskCache")).to be_falsey

          @session.reset!
          @session.visit("/cuprite/cacheable")

          expect(@driver.browser.network.traffic.last.response.params.dig("response", "fromDiskCache")).to be_truthy
        end

        it "clears cookies" do
          @session.visit("/set_cookie")
          expect(@driver.browser.cookies["capybara"]).not_to be_nil

          @session.reset!
          @session.visit("/get_cookie")

          expect(@driver.browser.cookies.all).to be_empty
          expect(@session.html).not_to include("test_cookie")
        end

        it "clears local storage, session storage and IndexedDB" do
          @session.visit("/cuprite/simple")
          @session.execute_script(<<~JS)
            localStorage.setItem("key", "local");
            sessionStorage.setItem("key", "session");
            indexedDB.open("cuprite_soft_reset");
          JS
          expect(@session.evaluate_async_script(<<~JS)).to include("cuprite_soft_reset")
            indexedDB.databases().then((dbs) => arguments[0](dbs.map((db) => db.name)));
          JS

          @session.reset!
          @session.visit("/cuprite/simple")

          expect(@session.evaluate_script("localStorage.getItem('key')")).to be_nil
          expect(@session.evaluate_script("sessionStorage.getItem('key')")).to be_nil
          expect(@session.evaluate_async_script(<<~JS)).to be_empty
            indexedDB.databases().then((dbs) => arguments[0](dbs.map((db) => db.name)));
          JS
        end

        it "closes extra windows" do
          @session.visit("/cuprite/simple")
          @session.switch_to_window(@session.open_new_window)
          @session.open_new_window
          expect(@session.windows.size).to eq(3)

          @session.reset!

          expect(@session.windows.size).to eq(1)
          @session.visit("/cuprite/simple")
          expect(@session).to have_content("Foo")
        end

        it "drops extra headers and offline mode" do
          @driver.browser.headers.set("X-Soft-Reset" => "kept")
          @session.visit("/cuprite/headers")
          expect(@session).to have_content("SOFT_RESET: kept")
          @driver.browser.network.offline_mode

          @session.reset!
          @session.visit("/cuprite/headers")

          expect(@session).to have_content("HOST")
          expect(@session).not_to have_content("SOFT_RESET")
        end

        it "falls back to the full reset when the soft one fails" do
          @session.visit("/set_cookie")
          context_id = @driver.browser.default_context.id
          allow(@driver.browser.default_context).to receive(:create_target).and_raise(Ferrum::TimeoutError)

          @session.reset!
          @session.visit("/get_cookie")

          expect(@driver.browser.default_context.id).not_to eq(context_id)
          expect(@driver.browser.cookies.all).to be_empty
        end
      end
    end
  end
end

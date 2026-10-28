---
sidebar_position: 1
---

# Introduction

Cuprite is a pure Ruby driver for [Capybara](https://github.com/teamcapybara/capybara).

<img align="right"
     width="160" height="160"
     alt="Cuprite logo"
     src="https://raw.githubusercontent.com/rubycdp/cuprite/main/logo.svg?sanitize=true" />

It allows you to run Capybara tests on a headless Chrome or Chromium with _no_
Selenium/WebDriver/ChromeDriver dependency. Under the hood it uses
[Ferrum](/docs/ferrum/introduction), a high-level API to the browser over the
[CDP protocol](https://chromedevtools.github.io/devtools-protocol/).

<br clear="right" />

## Installation

Download Chrome or Chromium from the official source for
[Chrome](https://www.google.com/chrome/) or [Chromium](https://www.chromium.org/getting-involved/download-chromium).
The binary should be in the `PATH` or `BROWSER_PATH`, or you can pass it with the
`:browser_path` option, see [Customization](/docs/cuprite/customization).

Add this to your `Gemfile` and run `bundle install`.

```ruby
group :test do
  gem "cuprite"
end
```

## Quick Start

In your test setup add:

```ruby
require "capybara/cuprite"

Capybara.javascript_driver = :cuprite
Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(app, window_size: [1200, 800])
end
```

Requiring `capybara/cuprite` already registers a `:cuprite` driver with default
options, so you only need to register it yourself if you want to customize it.

Then write your tests as usual:

```ruby
it "signs in", js: true do
  visit "/login"

  fill_in "Email", with: "user@example.com"
  fill_in "Password", with: "secret"
  click_button "Sign in"

  expect(page).to have_content("Welcome")
end
```

## Docker

See [Docker](/docs/cuprite/docker).

## Ferrum under the hood

`page.driver` is the Capybara driver. It implements what Capybara needs, plus a
few things that depend on Capybara, like frames, windows, modals and
screenshots saved to `Capybara.save_path`.

`page.driver.browser` is a `Ferrum::Browser`, so everything in the
[Ferrum documentation](/docs/ferrum/introduction) applies to it. Use it when
Capybara has no API for what you need:

```ruby
browser = page.driver.browser
browser.headers.set("Accept-Language" => "de")
browser.cookies.set(name: "stealth", value: "omg")
browser.network.wait_for_idle
browser.network.traffic.last.response.status # => 200
browser.mouse.move(x: 123, y: 456).down.up
browser.screenshot(format: :jpeg, quality: 60)
browser.console.select(&:error?)
browser.downloads.files
```

A few things to keep in mind:

- It follows Capybara. Page methods such as `browser.evaluate`, `browser.css`
  or `browser.current_url` run in the window and frame Capybara is switched to,
  for example inside `within_window` or `within_frame`.
- It's reset between tests. Capybara's reset disposes the browser context, so
  headers, cookies, request interception, recorded traffic, console messages
  and downloads are gone in the next test. Browser-wide settings such as
  `browser.timeout = 10` stay.
- It doesn't wait. Ferrum's finders return what's on the page right now, while
  Capybara's retry up to `Capybara.default_max_wait_time`. Prefer Capybara's
  finders and matchers in tests, and use `browser` for what Capybara can't do.

## Migrating from Selenium

Check your code for `page.driver.browser.manage` calls, there's no `manage` in
Cuprite. Use Capybara's API where it has one, for example
`page.current_window.resize_to`, and `page.driver.browser` for the rest, for
example [cookies](/docs/ferrum/cookies).

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

Since Cuprite is built on top of Ferrum there are many useful methods you can
call even using this driver. `page.driver.browser` is a `Ferrum::Browser`
instance:

```ruby
browser = page.driver.browser
browser.mouse.move(x: 123, y: 456).down.up
browser.network.emulate_network_conditions(offline: true)
```

See [Ferrum documentation](/docs/ferrum/introduction) for the full API.

## Migrating from Selenium

Check your code for `page.driver.browser.manage` calls, there's no `manage` in
Cuprite. Use driver methods instead, for example
[cookies](/docs/cuprite/cookies) or
[window resizing](/docs/cuprite/windows-frames).

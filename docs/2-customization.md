---
sidebar_position: 2
---

# Customization

You can pass options with the following code in your test setup:

```ruby
Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(app, options)
end
```

Cuprite accepts all [Ferrum options](/docs/ferrum/customization), such as
`:headless`, `:timeout`, `:js_errors`, `:browser_path`, `:browser_options`,
`:url`, `:proxy`, `:dockerize` and others.

Cuprite-specific options are:

* options `Hash`
  * `:screen_size` (Array) - Size used by `maximize_window`, `[1366, 768]` by default.
  * `:raise_on_unhandled_modal` (Boolean) - What to do when a JavaScript dialog is opened but not handled by
    `accept_*`/`dismiss_*`. When `false` (default) a warning is printed, when `true`
    `Capybara::Cuprite::UnhandledModalError` is raised. See [Modals](/docs/cuprite/modals).
  * `:url_blacklist` (Array) - Regexes to match against requested URLs that should be blocked, see
    [URL filtering](/docs/cuprite/url-filtering).
  * `:url_whitelist` (Array) - Regexes to match against requested URLs that are allowed, see
    [URL filtering](/docs/cuprite/url-filtering).
  * `:emulate` (Symbol) - Device to emulate, one of those listed in Chrome DevTools' device toolbar, such as
    `:iphone_16`, `:pixel_9`, `:samsung_galaxy_a55` or `:ipad_mini`, see `Capybara::Cuprite::Devices::LIST`. It sets
    the device's `:window_size`, `:scale_factor` and `:mobile`, options passed explicitly take precedence, and its
    user agent, unless a `User-Agent` is set with [headers](/docs/cuprite/headers).
  * `:mobile` (Boolean) - Emulate a mobile device: honor `<meta name="viewport">` and enable touch events, `false`
    by default. Kept across window resizes.
  * `:scale_factor` (Numeric) - Device scale factor (`window.devicePixelRatio`) to emulate, `0` (browser default)
    by default.

Cuprite changes a few Ferrum defaults:

* `:save_path` - defaults to `Capybara.save_path` if it's set.
* `:pending_connection_errors` - `true` by default.
* `:browser_options` - `"remote-allow-origins" => "*"` is always added, so that
  [debug](/docs/cuprite/debugging) can open DevTools, and so is `"disable-web-security" => nil`, so that tests
  can reach into cross-origin frames.

## Examples

```ruby
# Run in headful mode with slowmo for debugging
Capybara::Cuprite::Driver.new(app, headless: false, slowmo: 0.5)

# Raise JavaScript errors in Ruby
Capybara::Cuprite::Driver.new(app, js_errors: true)

# Increase timeout for slow CI machines
Capybara::Cuprite::Driver.new(app, timeout: 15, process_timeout: 30)

# Connect to a remote browser
Capybara::Cuprite::Driver.new(app, url: "http://chrome:3333")

# Leave the window size to Chrome, e.g. to start maximized in headful mode
Capybara::Cuprite::Driver.new(app, headless: false, window_size: nil, browser_options: { "start-maximized" => nil })

# Emulate an iPhone 14
Capybara::Cuprite::Driver.new(app, emulate: :iphone_14)

# Emulate a Pixel 9 with a custom scale factor
Capybara::Cuprite::Driver.new(app, emulate: :pixel_9, scale_factor: 1)
```

## Environment variables

* `CUPRITE_DEBUG` - When set, Ferrum prints all CDP messages to `STDOUT`.
* `BROWSER_PATH` - Path to the Chrome binary.
* `CUPRITE_MODAL_WAIT` - How often to check for a modal dialog while waiting for it, `0.05` seconds by default.
* `CUPRITE_TRIGGER_CLICK_WAIT` - How long to wait for a possible navigation after `trigger("click")`, `0.1` seconds
  by default.

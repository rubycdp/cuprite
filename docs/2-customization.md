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

Cuprite changes a few Ferrum defaults:

* `:save_path` - defaults to `Capybara.save_path` if it's set.
* `:pending_connection_errors` - `true` by default.
* `:browser_options` - `"remote-allow-origins" => "*"` is always added, so that
  [debug](/docs/cuprite/debugging) can open DevTools.

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
```

## Environment variables

* `CUPRITE_DEBUG` - When set, Ferrum prints all CDP messages to `STDOUT`.
* `BROWSER_PATH` - Path to the Chrome binary.
* `CUPRITE_MODAL_WAIT` - How often to check for a modal dialog while waiting for it, `0.05` seconds by default.
* `CUPRITE_TRIGGER_CLICK_WAIT` - How long to wait for a possible navigation after `trigger("click")`, `0.1` seconds
  by default.

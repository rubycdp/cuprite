---
sidebar_position: 7
---

# JavaScript

Cuprite supports `evaluate_script`, `evaluate_async_script` and
`execute_script`. Nodes can be passed as arguments and are returned as
Capybara elements.

```ruby
page.evaluate_script("1 + 1") # => 2
page.evaluate_script("arguments[0].innerText", find("h1")) # => "Title"
page.execute_script("document.body.style.background = 'red'")
page.evaluate_async_script(<<~JS, 100)
  const [delay, done] = arguments;
  setTimeout(() => done("ready"), delay);
JS
```

## JavaScript errors

Pass `js_errors: true` to re-raise JavaScript errors from the page as
`Ferrum::JavaScriptError` in Ruby:

```ruby
Capybara::Cuprite::Driver.new(app, js_errors: true)
```

## Console

`page.driver.browser.console` is Ferrum's [console](/docs/ferrum/javascript#console)
for the current page: `console.*` calls, browser log entries (failed resource
loads, CSP violations, deprecations, ...) and uncaught exceptions. It's
`Enumerable` over the last 1000 messages and is cleared at the end of every
test.

```ruby
visit "/"
page.driver.browser.console.last.text # => "Hello world"
page.driver.browser.console.select(&:error?) # => [#<Ferrum::Console::Message type=:error source=:network ...>]
```

Fail a test on browser errors:

```ruby
after { expect(page.driver.browser.console.select(&:error?)).to be_empty }
```

Print what the page logged:

```ruby
after { page.driver.browser.console.each { |message| warn(message) } }
```

## Preloading scripts

Use the `:extensions` option to load scripts into every page before any other
script runs:

```ruby
Capybara::Cuprite::Driver.new(
  app,
  extensions: [
    "/path/to/script.js",
    { source: "window.TESTING = true" }
  ]
)
```

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

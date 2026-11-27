---
sidebar_position: 10
---

# Network

Use Ferrum's [network](/docs/ferrum/network) for traffic, idle waiting and
cache. Traffic is cleared at the end of every test.

#### traffic : `Array<Ferrum::Network::Exchange>`

Returns network traffic (loaded resources), including requests blocked by
[URL filtering](/docs/cuprite/url-filtering). Each exchange contains request
and response details. Traffic is not cleared when you visit a new page.

```ruby
traffic = page.driver.current_page.network.traffic
exchange = traffic.first
exchange.request.url # => "http://127.0.0.1:3000/"
exchange.response.status # => 200

traffic.select(&:blocked?)
page.driver.current_page.network.clear(:traffic)
```

#### wait_idle(\*\*options) : `true` | `nil`

Waits until there are no active connections. Returns `true` on success and
`nil` if there are still connections after timeout. `wait_idle!` raises
`Ferrum::TimeoutError` instead.

* options `Hash`
  * :connections `Integer` how many connections are allowed for network to be idling, `0` by default
  * :interval `Float` sleep for given amount of time and check again, `0.05` by default
  * :timeout `Float` during what time we try to check idle, `browser.timeout` by default

```ruby
click_button "Save"
page.driver.current_page.network.wait_idle
```

#### clear(:cache)

Clears the browser cache.

```ruby
page.driver.current_page.network.clear(:cache)
```

#### await_navigation(\*\*options) { ... }

Ferrum's `await_navigation` runs the block and waits until the page it navigates
to is loaded. Returns `true`, or `nil` if it doesn't load within `timeout:`,
`browser.timeout` by default. `await_navigation!` raises `Ferrum::TimeoutError`
instead.

A click already waits for the page it opens, but only for a navigation that
starts within `FERRUM_NAVIGATION_WAIT`, 0.1 seconds. Use `await_navigation` with
`watch:` when the navigation starts later, for example when an autocomplete
suggestion loads data first and only then opens the page. Sleep makes you wait
longer or less than needed, and network idle can return before the navigation
even started.

```ruby
page.driver.current_page.await_navigation(watch: 1) { find(".suggestion").click }
```

#### status_code : `Integer`

Returns status code of the main page response.

```ruby
page.status_code # => 200
```

#### response_headers : `Hash`

Returns headers of the main page response.

```ruby
page.response_headers["Content-Type"] # => "text/html; charset=utf-8"
```

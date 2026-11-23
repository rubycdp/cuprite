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
traffic = page.driver.browser.network.traffic
exchange = traffic.first
exchange.request.url # => "http://127.0.0.1:3000/"
exchange.response.status # => 200

traffic.select(&:blocked?)
page.driver.browser.network.clear(:traffic)
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
page.driver.browser.network.wait_idle
```

#### clear(:cache)

Clears the browser cache.

```ruby
page.driver.browser.network.clear(:cache)
```

#### await_navigation(\*\*options) { ... }

Ferrum's `browser.await_navigation`, unlike `network.wait_idle`, runs the block
and waits until the page it reloads or navigates to is loaded. Returns `true`,
or `nil` if it doesn't load within `timeout:`, `browser.timeout` by default.
`await_navigation!` raises `Ferrum::TimeoutError` instead. Useful when you know
an action, like choosing an autocomplete suggestion, reloads the page. Sleep
makes you wait longer or less than needed, and network idle can return before
the page even started to reload.

```ruby
page.driver.browser.await_navigation { find(".suggestion").click }
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

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

#### wait_for_idle(\*\*options) : `Boolean`

Waits until there are no active connections. Returns `true` on success and
`false` if there are still connections after timeout.

* options `Hash`
  * :connections `Integer` how many connections are allowed for network to be idling, `0` by default
  * :duration `Float` sleep for given amount of time and check again, `0.05` by default
  * :timeout `Float` during what time we try to check idle, `browser.timeout` by default

```ruby
click_button "Save"
page.driver.browser.network.wait_for_idle
```

#### clear(:cache)

Clears the browser cache.

```ruby
page.driver.browser.network.clear(:cache)
```

`page.driver.network_traffic`, `clear_network_traffic`, `wait_for_network_idle`
and `clear_memory_cache` are deprecated in favor of these. Note that
`network_traffic` left out blocked requests by default, `traffic` doesn't.

#### wait_for_reload(timeout = 1)

Ferrum's `browser.wait_for_reload`, unlike `network.wait_for_idle`, waits until
the whole page is reloaded, or `timeout` seconds pass. Useful
when you know an action, like choosing an autocomplete suggestion, reloads the
page. Sleep makes you wait longer or less than needed, and network idle can
return before the page even started to reload.

```ruby
find(".suggestion").click
page.driver.browser.wait_for_reload
```

`page.driver.wait_for_reload` is deprecated in favor of it.

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

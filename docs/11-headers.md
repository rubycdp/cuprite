---
sidebar_position: 11
---

# Headers

Manipulate HTTP request headers with Ferrum's [headers](/docs/ferrum/headers).
Headers apply to all subsequent HTTP requests, including assets, AJAX, etc.
They are cleared at the end of every test.

```ruby
headers = page.driver.browser.headers
headers.get # => {}
headers.set("X-Trace" => "1")
headers.add({ "X-Tenant" => "acme" })
headers.get # => { "X-Trace" => "1", "X-Tenant" => "acme" }
```

`set` overwrites already set headers, `add` merges into them. A `Referer`
header is sent with every request, for the referrer of one navigation only pass
it to `go_to`:

```ruby
page.driver.browser.go_to("/landing", referrer: "https://example.com")
```

To change the user agent or the language use Ferrum's
[network.emulate](/docs/ferrum/network), which overrides the `User-Agent` and
`Accept-Language` headers together with what `navigator` reports. It is reset
at the end of every test too:

```ruby
page.driver.browser.network.emulate(user_agent: "Cuprite", accept_language: "de")
```

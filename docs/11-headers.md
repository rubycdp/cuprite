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
headers.set("User-Agent" => "Cuprite")
headers.add({ "Accept-Language" => "de" })
headers.get # => { "User-Agent" => "Cuprite", "Accept-Language" => "de" }
```

`set` overwrites already set headers, `add` merges into them. With
`permanent: false` a `Referer` header is applied to the next navigation only:

```ruby
page.driver.browser.headers.add({ "Referer" => "https://example.com" }, permanent: false)
```

`page.driver.headers`, `headers=`, `add_headers` and `add_header` are
deprecated in favor of these.

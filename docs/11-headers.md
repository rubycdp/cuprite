---
sidebar_position: 11
---

# Headers

Manipulate HTTP request headers. Headers apply to all subsequent HTTP requests,
including assets, AJAX, etc. They are cleared at the end of every test.

#### headers : `Hash`

Returns current headers.

```ruby
page.driver.headers # => {}
```

#### headers=(headers)

Sets headers, overwriting already set ones.

```ruby
page.driver.headers = { "User-Agent" => "Cuprite" }
```

#### add_headers(headers)

Adds headers to already set ones.

```ruby
page.driver.add_headers("Referer" => "https://example.com")
page.driver.headers # => { "User-Agent" => "Cuprite", "Referer" => "https://example.com" }
```

#### add_header(name, value, permanent: true)

Adds a single header. With `permanent: false` a `Referer` header is applied to
the next navigation only.

```ruby
page.driver.add_header("Referer", "https://example.com", permanent: false)
```

---
sidebar_position: 12
---

# Cookies

#### cookies : `Hash<String, Ferrum::Cookies::Cookie>`

Returns cookies accessible to the current page. The keys are cookie names, the
values are cookie objects with `name`, `value`, `domain`, `path`, `size`,
`secure?`, `httponly?`, `session?`, `samesite` and `expires` methods.

```ruby
page.driver.cookies["session_id"].value # => "abc"
```

#### set_cookie(name, value, options = {})

Sets a cookie. Domain defaults to the current page's host, or to
`Capybara.app_host` (or `127.0.0.1`) if no page was visited yet.

* options `Hash`
  * :domain `String`
  * :path `String`
  * :secure `Boolean`
  * :httponly `Boolean`
  * :samesite `String`
  * :expires `Time`

```ruby
page.driver.set_cookie("stealth", "omg", path: "/", expires: Time.now + 3600)
```

#### remove_cookie(name, \*\*options)

Removes a cookie. Domain defaults to the current page's host, you can pass
`:domain` or `:url`.

```ruby
page.driver.remove_cookie("stealth")
```

#### clear_cookies

Removes all cookies.

```ruby
page.driver.clear_cookies
```

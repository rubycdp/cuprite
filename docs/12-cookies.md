---
sidebar_position: 12
---

# Cookies

Manipulate cookies with Ferrum's [cookies](/docs/ferrum/cookies). Cookies are
cleared at the end of every test.

```ruby
cookies = page.driver.browser.cookies
cookies.set(name: "stealth", value: "omg", domain: "127.0.0.1", path: "/", expires: Time.now + 3600)
cookies["stealth"].value # => "omg"
cookies.all # => { "stealth" => #<Ferrum::Cookies::Cookie ...> }
cookies.remove(name: "stealth", domain: "127.0.0.1")
cookies.clear
```

Pass `domain:` to `set` and `remove`, it's the host your app runs on, which is
`127.0.0.1` for Capybara's server by default, or the host of
`Capybara.app_host`.

Cookie objects have `name`, `value`, `domain`, `path`, `size`, `secure?`,
`httponly?`, `session?`, `samesite` and `expires` methods.

`page.driver.cookies`, `set_cookie`, `remove_cookie` and `clear_cookies` are
deprecated in favor of these.

---
sidebar_position: 12
---

# Cookies

Manipulate cookies with Ferrum's [cookies](/docs/ferrum/cookies). Cookies are
cleared at the end of every test.

```ruby
cookies = page.driver.browser.cookies
cookies.set(name: "stealth", value: "omg", path: "/", expires: Time.now + 3600)
cookies["stealth"].value # => "omg"
cookies.all # => { "stealth" => #<Ferrum::Cookies::Cookie ...> }
cookies.remove(name: "stealth")
cookies.clear
```

`set` and `remove` default `domain:` to the host of the last `visit`, or to
`Capybara.app_host` (or Capybara's server) before the first visit. Pass
`domain:` for other hosts.

Cookie objects have `name`, `value`, `domain`, `path`, `size`, `secure?`,
`httponly?`, `session?`, `samesite` and `expires` methods.

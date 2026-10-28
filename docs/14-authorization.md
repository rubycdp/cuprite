---
sidebar_position: 14
---

# Authorization

Use Ferrum's [network.authorize](/docs/ferrum/network) to set
credentials for HTTP basic authentication. It intercepts requests, so the block
decides what happens to every request and has to continue it:

```ruby
page.driver.browser.network.authorize(user: "login", password: "pass") do |request, _index, _total|
  request.continue
end
visit "/admin"
```

Keep all three block arguments. With one, RuboCop's `Style/SymbolProc` turns the
block into `&:continue`, which raises `ArgumentError` because Ferrum passes
three.

Credentials are cleared at the end of every test.

`page.driver.authorize(user, password)` and `page.driver.basic_authorize` are
deprecated in favor of it.

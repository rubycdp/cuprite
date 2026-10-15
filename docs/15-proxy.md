---
sidebar_position: 15
---

# Proxy

#### set_proxy(host, port, user = nil, password = nil, bypass = nil)

Sets a proxy for the browser.

```ruby
page.driver.set_proxy("127.0.0.1", 8080, "user", "password", ["localhost"])
```

Or pass the `:proxy` option:

```ruby
Capybara::Cuprite::Driver.new(
  app,
  proxy: { host: "127.0.0.1", port: 8080, user: "user", password: "password", bypass: ["localhost"] }
)
```

The proxy is passed to Chrome as a command-line flag, so it has to be set before
the browser starts: either with the `:proxy` driver option or by calling
`set_proxy` before the browser is first used. Calling it once the browser is
running has no effect.

When connecting to a remote browser with the `:url` option (browserless,
Selenoid, etc.), Cuprite doesn't launch Chrome and the proxy flag is never
applied, so configure the proxy on the remote browser itself. The `user` and
`password` are still used to answer the proxy's authentication challenge.

The `bypass` argument is a list of hosts that skip the proxy, so don't pass the
host you want to go through it.

See Ferrum's [Proxy](/docs/ferrum/proxy) for more details.

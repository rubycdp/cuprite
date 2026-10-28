---
sidebar_position: 15
---

# Proxy

Pass the `:proxy` option to the driver:

```ruby
Capybara::Cuprite::Driver.new(
  app,
  proxy: { host: "127.0.0.1", port: 8080, user: "user", password: "password", bypass: ["localhost"] }
)
```

The proxy is passed to Chrome as a command-line flag when the browser starts.

When connecting to a remote browser with the `:url` option (browserless,
Selenoid, etc.), Cuprite doesn't launch Chrome and the proxy flag is never
applied, so configure the proxy on the remote browser itself. The `user` and
`password` are still used to answer the proxy's authentication challenge.

The `bypass` option is a list of hosts that skip the proxy, so don't pass the
host you want to go through it.

`page.driver.set_proxy` is deprecated in favor of the `:proxy` option.

See Ferrum's [Proxy](/docs/ferrum/proxy) for more details.

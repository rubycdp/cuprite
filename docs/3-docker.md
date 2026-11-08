---
sidebar_position: 3
---

# Docker

If Chrome or Chromium cannot use its sandbox inside a container, for example,
because it runs as `root`, enable Ferrum's container mode:

```ruby
Capybara::Cuprite::Driver.new(app, dockerize: true)
```

The `:dockerize` option requires Ferrum 0.17.2 or newer. With an older Ferrum
version, pass the browser option explicitly:

```ruby
Capybara::Cuprite::Driver.new(
  app,
  browser_options: { "no-sandbox" => nil }
)
```

Both approaches disable the browser's sandbox, so do not use them merely
because Docker is involved. Prefer running the browser as a non-root user with
a working sandbox when possible.

## Remote browser

You can run Chrome in a separate container and connect to it with the `:url`
option, Cuprite won't spawn a browser process then:

```ruby
Capybara.server_host = "0.0.0.0"
Capybara.app_host = "http://#{Socket.gethostname}:#{Capybara.server_port}"

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(app, url: "http://chrome:3333")
end
```

See Ferrum's [Docker](/docs/ferrum/docker) page for details about init
processes, Kubernetes and cleaning up zombie processes.

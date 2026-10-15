---
sidebar_position: 16
---

# URL Filtering

Cuprite supports URL blocklisting, which allows you to prevent requests to
designated URLs:

```ruby
page.driver.browser.url_blocklist = [%r{http://www.example.com}]
```

and also URL allowlisting, which allows requests only to designated URLs:

```ruby
page.driver.browser.url_allowlist = [%r{http://127.0.0.1}]
```

You can also set them with the `:url_blacklist` and `:url_whitelist` driver options:

```ruby
Capybara::Cuprite::Driver.new(
  app,
  url_blacklist: [/google-analytics\.com/, /facebook\.net/]
)
```

Lists set at runtime are reset to the driver options at the end of every test.
If both lists are set, the blocklist takes precedence. Blocked requests can be
inspected with `page.driver.network_traffic(:blocked)`.

`url_blacklist=` and `url_whitelist=` setters continue to work for legacy support.
Passing strings instead of regexes is deprecated, `*` is treated as a wildcard
in that case.

If you are experiencing slower run times, consider creating an allowlist of
domains that are essential or a blocklist of domains that are not, such as ad
networks or analytics.

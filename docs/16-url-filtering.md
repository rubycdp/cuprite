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

`url_blacklist=` and `url_whitelist=` are aliases of the same setters, and the
driver options take either name:

```ruby
Capybara::Cuprite::Driver.new(
  app,
  url_blacklist: [/google-analytics\.com/, /facebook\.net/]
)
```

Lists set at runtime are reset to the driver options at the end of every test.
Only one list can be set at a time, setting both raises `ArgumentError`, and so
does a string pattern, pass regexes. An empty list lifts the blocklist at once,
and the allowlist from the next page on. Blocked requests can be inspected with
`page.driver.browser.network.traffic.select(&:blocked?)`.

If you are experiencing slower run times, consider creating an allowlist of
domains that are essential or a blocklist of domains that are not, such as ad
networks or analytics.

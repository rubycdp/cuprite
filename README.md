# Cuprite - Headless Chrome driver for Capybara #

[![Build Status](https://travis-ci.org/machinio/cuprite.svg?branch=master)](https://travis-ci.org/machinio/cuprite)

Cuprite is a pure Ruby driver (read as _no_ Java/Selenium/WebDriver/ChromeDriver
requirement) for [Capybara](https://github.com/teamcapybara/capybara). It allows
you to run your Capybara tests on a headless [Chrome](https://www.google.com/chrome/)
or [Chromium](https://www.chromium.org/) browser while the latter is prefered
for now because we work with tip-of-tree [protocol](https://chromedevtools.github.io/devtools-protocol/).

The emphasis was made on raw CDP protocol because Headless Chrome allows you to
do so many cool things that are barely supported by WebDriver because it should
have consistent design with other browsers. The design of the driver will be as
close to [Poltergeist](https://github.com/teampoltergeist/poltergeist) as
possible but it's not a goal.

## Speed comparison and missing features ##

Almost all capybara tests are passing with quite good speed in comparison with
Poltergest/PhantomJS:

```
cuprite:
Finished in 8 minutes 44 seconds (files took 0.97501 seconds to load)
1531 examples, 0 failures, 112 pending

selenium headless chrome:
Finished in 9 minutes 13 seconds (files took 0.97749 seconds to load)
1445 examples, 0 failures, 3 pending

poltergeist:
Finished in 11 minutes 49 seconds (files took 0.54019 seconds to load)
1560 examples, 0 failures, 6 pending
```

## Installation ##

``` ruby
gem "cuprite"
```

Though we recommend using github until we release 1.0:
``` ruby
gem "cuprite", github: "machinio/cuprite"
```

and run `bundle install`.

In your test setup add:

``` ruby
require "capybara/cuprite"
Capybara.javascript_driver = :cuprite
```

If you were previously using the `:rack_test` driver, be aware that
your app will now run in a separate thread and this can have
consequences for transactional tests. [See the Capybara README for more detail](https://github.com/jnicklas/capybara/blob/master/README.md#transactions-and-database-setup).

## Installing Chromium ##

As Chromium is stopped being built as a package for Linux don't even try to
install it this way because it will either be outdated or unofficial package.
Both are bad. Download it from official [source](https://www.chromium.org/getting-involved/download-chromium).

## Supported features ##

All the mandatory capybara features plus optional ones:

* `page.evaluate_script` and `page.execute_script`
* `page.within_frame`
* `page.status_code`
* `page.response_headers`
* `page.save_screenshot`
* `page.driver.render_base64(format, options)`
* window API
* cookie handling

### Clicking coordinates ###

Sometimes its desirable to click a very specific area of the screen. You can
accomplish this with `page.driver.click(x, y)`, where x and y are the screen
coordinates.

### Manipulating request headers ###

Manipulate HTTP request headers like a boss:

``` ruby
page.driver.headers # => {}
page.driver.headers = { "User-Agent" => "Cuprite" }
page.driver.add_headers("Referer" => "https://example.com")
page.driver.headers # => { "User-Agent" => "Cuprite", "Referer" => "https://example.com" }
```

Notice that `headers=` will overwrite already set headers. You should use
`add_headers` if you want to add a few more. These headers will apply to all
subsequent HTTP requests (including requests for assets, AJAX, etc). They will
be automatically cleared at the end of the test.

### Inspecting network traffic ###

You can inspect the network traffic (i.e. what resources have been loaded) on
the current page by calling `page.driver.network_traffic`. This returns an array
of request objects. A request object has a `response` method containing data
about the response.

Please note that network traffic is not cleared when you visit new page. You can
manually clear the network traffic by calling `page.driver.clear_network_traffic`
or `page.driver.reset`

### Manipulating cookies ###

The following methods are used to inspect and manipulate cookies:

* `page.driver.cookies` - a hash of cookies accessible to the current
  page. The keys are cookie names. The values are `Cookie` objects, with
  the following methods: `name`, `value`, `domain`, `path`, `size`, `secure?`,
  `httponly?`, `session?`, `expires`.
* `page.driver.set_cookie(name, value, options = {})` - set a cookie.
  The options hash can take the following keys: `:domain`, `:path`,
  `:secure`, `:httponly`, `:expires`. `:expires` should be a
  `Time` object.
* `page.driver.remove_cookie(name)` - remove a cookie
* `page.driver.clear_cookies` - clear all cookies

## Customization ##

You can customize the way that Capybara sets up Cuprite via the following code
in your test setup:

``` ruby
Capybara.register_driver :cuprite do |app|
  Capybara::Cuprite::Driver.new(app, options)
end
```

`options` is a hash of options. The following options are supported:

* `:browser` (Hash) - Hash of options to be passed to chrome process:
  * `:path` (String) - Path to chrome binary, you can also set ENV variable as
    `BROWSER_PATH=some/path/chrome bundle exec rspec`
  * `:window_size` (Array) - The dimensions of the browser window in which to
    test, expressed as a 2-element array, e.g. [1024, 768]. Default: [1024, 768]
  * `:port` (Integer) - Remote debugging port for headless Chrome
  * `:host` (String) - Remote debugging address for headless Chrome
* `:js_errors` (Boolean) - When true, JavaScript errors get re-raised in Ruby.
* `:logger` (Object responding to `puts`) - When present, debug output is
    written to this object.
* `:timeout` (Numeric) - The number of seconds we'll wait for a response when
    communicating with browser. Default is 30.
* `:extensions` (Array) - An array of JS files to be preloaded into the browser
* `:url_blacklist` (Array) - array of strings to match against requested URLs
* `:url_whitelist` (Array) - array of strings to match against requested URLs


### URL Blacklisting & Whitelisting ###
Cuprite supports URL blacklisting, which allows you to prevent scripts from
running on designated domains:

```ruby
page.driver.browser.url_blacklist = ['http://www.example.com']
```

and also URL whitelisting, which allows scripts to only run
on designated domains:

```ruby
page.driver.browser.url_whitelist = ['http://www.example.com']
```

If you are experiencing slower run times, consider creating a URL whitelist of
domains that are essential or a blacklist of domains that are not essential,
such as ad networks or analytics, to your testing environment.

## License ##

Copyright 2018-2019 Machinio

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

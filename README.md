# Cuprite - Headless Chrome driver for Capybara #

Cuprite is a pure Ruby driver (read as _no_ Java/Selenium/WebDriver/ChromeDriver
requirement) for [Capybara](https://github.com/teamcapybara/capybara). It allows
you to run your Capybara tests on a headless [Chrome](https://www.google.com/chrome/)
or [Chromium](https://www.chromium.org/) browser while the latter is prefered
for now because we work with tip-of-tree [protocol](https://chromedevtools.github.io/devtools-protocol/).

The emphasis was made on raw CDP protocol because Headless Chrome allows you to
do so many cool things that are barely supported by WebDriver because it should
have consistent design with other browsers.

## Installation ##

Add this line to your Gemfile and run `bundle install`:

``` ruby
gem "cuprite"
```

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

## Known issues ##

# Race condition:

Failures:

  1) Capybara::Session with cuprite driver current_url returns about:blank when on about:blank
     Failure/Error: raise BrowserError.new(error) if error

     Capybara::Cuprite::BrowserError:
       Cannot find context with specified id
     # ./lib/capybara/cuprite/browser/client.rb:52:in `handle'
     # ./lib/capybara/cuprite/browser/client.rb:23:in `command'
     # ./lib/capybara/cuprite/browser/page.rb:102:in `command'
     # ./lib/capybara/cuprite/evaluate.rb:65:in `call'
     # ./lib/capybara/cuprite/evaluate.rb:41:in `evaluate'
     # ./lib/capybara/cuprite/browser.rb:43:in `current_url'
     # ./lib/capybara/cuprite/driver.rb:42:in `current_url'
     # /home/route/Projects/Ruby/capybara/lib/capybara/session.rb:216:in `current_url'
     # ./spec/integration/session_spec.rb:598:in `block (4 levels) in <top (required)>'

## License ##

Copyright 2018 Machinio

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

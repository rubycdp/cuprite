# Cuprite - Headless Chrome driver for Capybara #

Cuprite is a pure Ruby driver (read as _no_ Java/Selenium/WebDriver/ChromeDriver
requirement) for [Capybara](https://github.com/teamcapybara/capybara). It allows
you to run your Capybara tests on a headless [Chrome](https://www.google.com/chrome/)
or [Chromium](https://www.chromium.org/) browser while the latter is prefered
for now because we work with tip-of-tree [protocol](https://chromedevtools.github.io/devtools-protocol/).

The emphasis was made on raw CDP protocol because Headless Chrome allows you to
do so many cool things that are barely supported by WebDriver because it should
have consistent design with other browsers. The design of the driver will be as
close to [Poltergeist](https://github.com/teampoltergeist/poltergeist) as
possible but it is not the goal.

## Installation ##

It's not released on rubygems because it's not ready yet but a very decent
amount of tests is passing with quite good speed if compared to PhantomJS:

```
cuprite:
Finished in 3 minutes 31.6 seconds (files took 1.46 seconds to load)
1510 examples, 0 failures, 221 pending

poltergeist:
Finished in 7 minutes 6 seconds (files took 0.59349 seconds to load)
1560 examples, 0 failures, 6 pending
```

Add it to your project as:

``` ruby
gem "cuprite", github: "machinio/cuprite"
```

Whenever it's released add this line to your Gemfile:

``` ruby
gem "cuprite"
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

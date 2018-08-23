# Cuprite - Headless Chrome driver for Capybara #

Cuprite is a pure Ruby driver (which basically means no java/selenium/webdriver
/chromedriver dependency) for [Capybara](https://github.com/teamcapybara/capybara).
It allows you to run your Capybara tests on a headless [Chrome](https://www.google.com/chrome/)
or [Chromium](https://www.chromium.org/) browser while the latter is prefered
for now because we work with tip-of-tree [protocol](https://chromedevtools.github.io/devtools-protocol/).

The emphasis was made on raw CDP protocol because Headless Chrome allows you to
do so many cool things that are barely supported by webdriver because it should
have consistent design with other browsers.

## Work is still in progress ##

Copyright 2018 Dmitry Vorotilin

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

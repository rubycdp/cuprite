---
sidebar_position: 17
---

# Errors

All Cuprite errors inherit from `Capybara::Cuprite::Error`.

* `Capybara::Cuprite::ObsoleteNode` - The element is no longer attached to the
  DOM. It may have been replaced with another element, find it again.
* `Capybara::Cuprite::MouseEventFailed` - Another element is overlapping the one
  you're trying to click at the computed coordinates. Use
  `node.trigger("click")` if you don't care about overlapping elements.
* `Capybara::Cuprite::InvalidSelector` - The browser couldn't parse a CSS or
  XPath selector.
* `Capybara::Cuprite::UnhandledModalError` - A JavaScript dialog was opened
  without being handled, raised only with `raise_on_unhandled_modal: true`. See
  [Modals](/docs/cuprite/modals).

Ferrum errors such as `Ferrum::TimeoutError`, `Ferrum::DeadBrowserError` or
`Ferrum::JavaScriptError` can be raised as well. When the browser dies Cuprite
restarts it automatically for the next command.

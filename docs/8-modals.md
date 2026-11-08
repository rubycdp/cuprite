---
sidebar_position: 8
---

# Modals

Cuprite supports Capybara's modal API for `alert`, `confirm` and `prompt`:

```ruby
accept_alert { click_button "Show alert" }
accept_confirm("Are you sure?") { click_button "Delete" }
dismiss_confirm { click_button "Delete" }
accept_prompt(with: "Linus") { click_button "Ask name" }
dismiss_prompt { click_button "Ask name" }
```

## Unhandled modals

A JavaScript dialog opened without being wrapped in one of the methods above is
always accepted. By default Cuprite prints a warning. With
`raise_on_unhandled_modal: true` it raises
`Capybara::Cuprite::UnhandledModalError` instead:

```ruby
Capybara::Cuprite::Driver.new(app, raise_on_unhandled_modal: true)
```

The error is raised on the next command sent to the browser. In practice that's
almost always the same action that triggered the dialog (a click, `visit`,
`evaluate_script`, ...), since a JavaScript dialog blocks the page until it's
answered. A dialog fired with nothing in flight, e.g. by a JavaScript timer,
surfaces on whatever command runs next.

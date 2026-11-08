---
sidebar_position: 5
---

# Mouse & Keyboard

Besides the regular Capybara API, the driver exposes low-level helpers.

#### send_keys(\*keys)

Sends keys to the currently focused element.

```ruby
page.driver.send_keys("Hello", :enter)
page.driver.send_keys([:ctrl, "a"], :backspace)
```

#### active_element : `Capybara::Cuprite::Node`

Returns the currently focused element, it also powers Capybara's `:focused`
filter.

```ruby
page.driver.active_element
expect(page).to have_field("Email", focused: true)
```

## Ferrum mouse and keyboard

For more control use [Ferrum's mouse and keyboard](/docs/ferrum/mouse-keyboard):

```ruby
browser = page.driver.browser
browser.mouse.click(x: 100, y: 200)
browser.mouse.move(x: 123, y: 456).down.up
browser.mouse.scroll_by(0, 400)
browser.keyboard.type("text", :Enter)
```

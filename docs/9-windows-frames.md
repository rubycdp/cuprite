---
sidebar_position: 9
---

# Windows & Frames

## Windows

Cuprite supports Capybara's window API:

```ruby
new_window = window_opened_by { click_link "Open in new tab" }
within_window(new_window) do
  expect(page).to have_content("New tab")
end

switch_to_window(windows.first)
new_window.close
open_new_window
```

#### current_page : `Ferrum::Page`

`page.driver.browser.page` is always the first window. The Ferrum page of the
window Capybara is switched to is `page.driver.current_page`:

```ruby
within_window(new_window) do
  page.driver.current_page.network.traffic
  page.driver.current_page.screenshot(path: "tab.png")
end
```

## Window size

#### resize_to(width, height)

Capybara's way to resize a window, it waits until the new size is applied.

```ruby
page.current_window.resize_to(1024, 768)
```

#### maximize_window(handle)

Resizes the window to `:screen_size`, `[1366, 768]` by default.

```ruby
page.current_window.maximize
```

#### fullscreen_window(handle)

Switches the window into fullscreen mode.

```ruby
page.current_window.fullscreen
```

#### window_size(handle) : `Array`

Returns inner width and height of the window.

```ruby
page.current_window.size # => [1024, 768]
```

The window size is reset to `:window_size` at the end of every test. With `window_size: nil` Cuprite doesn't
set the size, so Chrome's own one, or `start-maximized`, applies.

## Frames

```ruby
within_frame("payment") do
  fill_in "Card number", with: "4242424242424242"
end

switch_to_frame(find("iframe"))
switch_to_frame(:parent)
switch_to_frame(:top)
```

Capybara's finders and `evaluate_script` run in the frame switched to. Ferrum's
own methods don't, `page.driver.current_page.css` searches the main frame. Reach
a frame through Ferrum with `page.driver.current_page.frame_by(name: "payment")`.

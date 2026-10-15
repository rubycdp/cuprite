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

## Window size

#### resize(width, height)

Resizes the current window. Also aliased as `resize_window`.

```ruby
page.driver.resize(1024, 768)
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

The window size is reset to `:window_size` at the end of every test.

## Frames

```ruby
within_frame("payment") do
  fill_in "Card number", with: "4242424242424242"
end

switch_to_frame(find("iframe"))
switch_to_frame(:parent)
switch_to_frame(:top)
```

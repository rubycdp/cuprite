---
sidebar_position: 13
---

# Screenshots

#### save_screenshot(path, options = {})

Capybara's `save_screenshot` saves an image or a PDF if the path ends with
`.pdf`. Also aliased as `render`. Accepts all options of Ferrum's
[screenshot and pdf](/docs/ferrum/screenshots) methods.

```ruby
page.save_screenshot("page.png", full: true)
page.save_screenshot("button.png", selector: "#submit")
page.save_screenshot("page.jpg", quality: 60)
page.save_screenshot("page.pdf", landscape: true)
```

Screenshots are saved to `Capybara.save_path` when a relative path is given.

#### render_base64(format = :png, options = {}) : `String`

Returns an image or a PDF as Base64.

```ruby
page.driver.render_base64(:png, full: true)
page.driver.render_base64(:jpeg, quality: 60)
page.driver.render_base64(:png, format: :pdf)
```

#### zoom_factor=(value)

Sets scale for subsequent screenshots and PDFs.

```ruby
page.driver.zoom_factor = 2
```

#### paper_size=(size)

Sets paper size in inches for subsequent PDFs.

```ruby
page.driver.paper_size = { width: 8.5, height: 11 }
page.save_screenshot("page.pdf")
```

Zoom factor and paper size are reset at the end of every test.

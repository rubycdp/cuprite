---
sidebar_position: 13
---

# Screenshots

#### save_screenshot(path, options = {})

Capybara's `save_screenshot` saves an image or a PDF if the path ends with
`.pdf`. Accepts all options of Ferrum's
[screenshot and pdf](/docs/ferrum/screenshots) methods.

```ruby
page.save_screenshot("page.png", full: true)
page.save_screenshot("button.png", selector: "#submit")
page.save_screenshot("page.jpg", quality: 60)
page.save_screenshot("zoomed.png", scale: 2)
page.save_screenshot("page.pdf", landscape: true)
page.save_screenshot("page.pdf", paper_width: 8.5, paper_height: 11)
page.save_screenshot("page.pdf", format: :A4)
```

Screenshots are saved to `Capybara.save_path` when a relative path is given.

## Base64

Ferrum's `screenshot` and `pdf` return Base64 when no `path:` is given:

```ruby
page.driver.browser.screenshot(format: :png, full: true)
page.driver.browser.screenshot(format: :jpeg, quality: 60)
page.driver.browser.pdf(paper_width: 8.5, paper_height: 11)
```

---
sidebar_position: 18
---

# Downloads

Files are saved to `Capybara.save_path`, or to the `:save_path` driver option
if given. `page.driver.browser.downloads` is Ferrum's
[downloads](/docs/ferrum/downloads) object for the current page.

#### await_download(timeout: 5) { ... }

Runs the block and waits until the download it starts is finished. Returns the
file information, or `nil` if it doesn't finish within 5 seconds, pass
`timeout:` to change it. `await_download!` raises `Ferrum::TimeoutError` instead.

```ruby
page.driver.browser.await_download { click_link "Export" }
# => {"url"=>"http://127.0.0.1/export.csv", "suggestedFilename"=>"export.csv", "state"=>"completed", ...}
```

#### files : `Array<Hash>`

Returns information about files downloaded since the last reset.

```ruby
page.driver.browser.downloads.files.last
# => {"url"=>"http://127.0.0.1/export.csv", "suggestedFilename"=>"export.csv", "totalBytes"=>4911,
#     "receivedBytes"=>4911, "state"=>"completed", ...}

File.read(File.join(Capybara.save_path, "export.csv"))
```

The list is cleared at the end of every test, files on disk are not removed.

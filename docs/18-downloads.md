---
sidebar_position: 18
---

# Downloads

Files are saved to `Capybara.save_path`, or to the `:save_path` driver option
if given. `page.driver.downloads` is Ferrum's
[downloads](/docs/ferrum/downloads) object for the current page.

#### wait(timeout = 5)

Waits until the current download is finished. Pass a block that starts it.

```ruby
page.driver.downloads.wait { click_link "Export" }
```

#### files : `Array<Hash>`

Returns information about files downloaded since the last reset.

```ruby
page.driver.downloads.files.last
# => {"url"=>"http://127.0.0.1/export.csv", "suggestedFilename"=>"export.csv", "totalBytes"=>4911,
#     "receivedBytes"=>4911, "state"=>"completed", ...}

File.read(File.join(Capybara.save_path, "export.csv"))
```

The list is cleared at the end of every test, files on disk are not removed.

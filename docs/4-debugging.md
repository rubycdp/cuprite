---
sidebar_position: 4
---

# Debugging

#### debug(binding = nil)

Pauses the test and opens DevTools for the current page in a new Chrome window,
where you can inspect the content. If you pass `binding`, a `pry` (if loaded) or
`irb` console is opened where you can further experiment with the test.

```ruby
it "does something useful" do
  visit root_path

  fill_in "field", with: "value"
  page.driver.debug(binding)

  expect(page).to have_content("value")
end
```

#### pause

Pauses the test until you press Enter or send `SIGCONT` to the process
(`kill -CONT <pid>`). Useful together with `headless: false`.

```ruby
page.driver.pause
```

## Headful mode

Run the browser with UI and slow down every command to see what's going on:

```ruby
Capybara::Cuprite::Driver.new(app, headless: false, slowmo: 0.5)
```

## Logging

Set `CUPRITE_DEBUG` to print all CDP messages exchanged with the browser:

```bash
CUPRITE_DEBUG=true bundle exec rspec
```

Or pass a logger object responding to `puts`:

```ruby
Capybara::Cuprite::Driver.new(app, logger: StringIO.new)
```

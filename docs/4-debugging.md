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

#### Pausing without DevTools

Run the test with `headless: false` and put a Ruby breakpoint where you want it
to stop:

```ruby
binding.irb
```

## Headful mode

Run the browser with UI and slow down every command to see what's going on:

```ruby
Capybara::Cuprite::Driver.new(app, headless: false, slowmo: 0.5)
```

## Logging

Set `CUPRITE_LOG=*` to print all CDP messages exchanged with the browser and Chrome's output:

```bash
CUPRITE_LOG=* bundle exec rspec
```

`CUPRITE_LOG` takes the same values as Ferrum's
[`FERRUM_LOG`](https://github.com/rubycdp/ferrum/blob/main/docs/2-customization.md), e.g. `CUPRITE_LOG=*,-browser`
leaves out Chrome's output. A `FERRUM_LOG` already set wins.

Or pass a logger object responding to `puts`:

```ruby
Capybara::Cuprite::Driver.new(app, logger: StringIO.new)
```

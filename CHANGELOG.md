## [Unreleased](https://github.com/rubycdp/cuprite/compare/v0.19...main) ##

### Changed
- `Browser#window_handle` is renamed to `Browser#current_window_handle`
- Node helpers on `Capybara::Cuprite::Browser` (`value`, `set`, `select`, `visible_text`, `drag`, etc.) are private, use
  Capybara's node API or `node.native.node` for Ferrum's
- `Driver#find`, `Driver#screen_size`, `Node#command` and `Node#description` are private, use `node.node.description`
  for the latter
- Ferrum's `base_url` follows `Capybara.app_host` (or Capybara's server) and the visited page, so
  `page.driver.browser.cookies` doesn't need `domain:`

### Deprecated
- Deprecated methods print a warning and will be removed in 0.21
- `Driver#body`, use `Driver#html` instead
- `Driver#back` and `Driver#forward`, use `Driver#go_back` and `Driver#go_forward` instead
- `Driver#window_handle`, use `Driver#current_window_handle` instead
- `Driver#render`, use `Driver#save_screenshot` instead
- `Driver#render_base64`, use `page.driver.browser.screenshot` or `page.driver.browser.pdf` instead
- `Driver#resize` and `Driver#resize_window`, use `page.current_window.resize_to` instead
- `Driver#authorize` and `Driver#basic_authorize`, use `page.driver.browser.network.authorize` instead
- `Driver#headers`, `headers=`, `add_headers` and `add_header`, use `page.driver.browser.headers` instead
- `Driver#cookies`, `set_cookie`, `remove_cookie` and `clear_cookies`, use `page.driver.browser.cookies` instead
- `Driver#network_traffic`, `clear_network_traffic`, `wait_for_network_idle` and `clear_memory_cache`, use
  `page.driver.browser.network` instead. `network.traffic` includes blocked requests
- `Driver#click`, use `page.driver.browser.mouse.click` instead
- `Driver#scroll_to`, use `page.scroll_to` instead
- `Driver#wait_for_reload`, `timeout`, `timeout=`, `device_pixel_ratio` and `viewport_size`, use the same methods on
  `page.driver.browser` instead
- `Driver#set_proxy`, pass the `:proxy` option to the driver instead
- `Node#send_key`, use `Node#send_keys` instead
- `Node#parents`, use Capybara's `ancestor` instead
- `Node#property` and `Node#attributes`, use `node.native.node.property` and `node.native.node.attribute` instead
- `Driver#zoom_factor=` and `Driver#paper_size=`, pass `scale:`, `paper_width:` and `paper_height:` to
  `save_screenshot` instead

### Fixed
- `Node#drag_to` with `drop_modifiers:` holds the modifiers while moving to the target and sends keydown and keyup for
  them, like Selenium does. They used to be set only on mouseup [rubycdp/ferrum#581]

### Removed
- Ruby 3.1 support, Cuprite requires Ruby 3.2 or newer
- `format: :pdf` in `Driver#save_screenshot`, broken since Ferrum 0.6. A `.pdf` path renders a PDF
- `Driver#source`, it always raised `NotImplementedError`. Use `page.html` or `page.source` instead
- `Capybara::Cuprite::Cookie`, it was never loaded. `Driver#cookies` returns `Ferrum::Cookies::Cookie` objects
- `Page#frame_name`, it was unused
- `Page#reset_modals` and `Browser#reset_modals`, they were unused
- `Browser#switch_to_frame`, `find_modal`, `accept_confirm`, `dismiss_confirm`, `accept_prompt` and `dismiss_prompt`, they
  were internal delegates to `Page`
- `Browser#browser_error`, it was used only in specs
- `Node#as_json` and `Node#to_json`, they were unused
- `Driver#pause`, use `binding.irb` with `headless: false`, or `Driver#debug`


## [0.19](https://github.com/rubycdp/cuprite/compare/v0.18...v0.19) ##

### Added
- `:emulate` driver option to emulate a device listed in Chrome DevTools with its user agent, e.g.
  `emulate: :iphone_14`, along with `:mobile` and `:scale_factor` options it sets, kept across window resizes [#216]
- `Node#drag_to` accepts `x:` and `y:` to drop at an offset from the target, measured from its center or top left like
  `click`, so drop targets that tell the upper half from the lower one can be driven [#325]

### Changed
- Ferrum is bumped to `~> 0.19.1`
- `--disable-web-security` is added to the browser options, since Ferrum dropped it from its defaults. Tests keep
  reaching into cross-origin frames, e.g. `current_url` within a frame from another origin [rubycdp/ferrum#472]
- Change `Node#send_keys` to avoid triggering `click` on an already focused element. `send_keys(:tab)` without an
  element no longer clicks the middle of the page first, so Tab moves focus from the start of the page, and Capybara's
  `#active_element` and `focused:` specs run in the suite [#327]

### Fixed
- `Node#drag_to` fired `dragleave` right before `drop` on an HTML5 drop target, which browsers never do, so libraries such
  as Pragmatic drag and drop dropped onto nothing. A drag now ends with `drop` if the target accepted it, otherwise
  with `dragleave` [#325]
- `window_size: nil` raised `Ferrum::BrowserError: Invalid parameters` on every page instead of leaving the window
  size to Chrome, so `start-maximized` couldn't be used [#278]
- `Driver#reset!` kept the page it had cached when the browser failed to reset, so every later example raised
  `Session with given id not found` or `Browser is dead or given window is closed` instead of starting on a fresh
  page [#274], [rubycdp/ferrum#641]
- `Node#visible?` reported an open popover or modal dialog as hidden when an ancestor had `opacity: 0` [#328]
- `Driver#window_handles` listed the web workers a page spawned as windows, so `window_opened_by` raised
  `opened 2 windows instead of 1` [#326]
- `Node#select_option` and `Node#unselect_option` didn't fire the `input` event on the select [#223]
- `Node#trigger` silently dispatched nothing for events other than mouse, focus and `submit`, such as `input`,
  `change` or custom events [#197]
- `Node#set` with an empty string cleared a text field without firing the `input` event [#164]
- Finders with `exact_text: true` raised `InvalidSelector` because Capybara appended an empty `[]` predicate to the
  XPath [#256]

## [0.18](https://github.com/rubycdp/cuprite/compare/v0.17...v0.18) ##

### Added
- Support time inputs [#245]
- Add initial support for shadow_root [#234]
- Support `Capybara::Cuprite::Node#rect` [#276]
- Extend `Node#set` with the `datetime-local` input type [#295]
- Support HTML5 drag-and-drop and drag modifier keys in `Node#drag_to` [#315]
- Support `Element#drop` for files and strings [#316]
- Add `:raise_on_unhandled_modal` browser option to raise instead of warn on an unhandled modal [#320]

### Changed
- Bump Ferrum dependency to `~> 0.18.0`

### Fixed
- Ensure the node has focus before setting value [#280]
- Raise `ObsoleteNode` instead of silently acting on a node that got disconnected from the DOM between being found and being used [#239]
- `Capybara::Cuprite::Node#send_keys` ignores empty or nil keys instead of raising, matching the Selenium and rack_test drivers [#313]
- `Driver#switch_to_frame` accepts a `Capybara::Cuprite::Node` instead of only a wrapped `Capybara::Node::Element` [#312]
- Report `tag_name` as `"ShadowRoot"` for shadow root nodes [#318]
- Treat non-summary descendants of a closed `<details>` element as non-visible [#317]
- `switch_to_window` sends `Target.activateTarget` so Chrome reactivates the window's renderer immediately instead of leaving it backgrounded, which could stall the next input command for several seconds [#321]
- `Node#set` fires `input` and `change` events for a `color` input, since its value can only be set via JavaScript and never gets them naturally [#229]
- Generate a `FocusEvent` (not a generic `Event`) for focus-related events (`blur`, `focus`, `focusin`, `focusout`), matching real browser behavior [#272]

### Removed


## [0.17](https://github.com/rubycdp/cuprite/compare/v0.16...v0.17) ##

### Added

### Changed
- `:inspector` option is retired

### Fixed
- Correctly open devtools page when calling `debug` [#296, #297]

### Removed


## [0.16](https://github.com/rubycdp/cuprite/compare/0.16) - (May 10, 2025) ##

### Added

### Changed
- `wait_for_network_idle` doesn't raise error, instead simply returns `nil`

### Fixed
- Assigning broken unicode to a node directly from JS can lead to `JSON::ParserError: incomplete surrogate pair at ...` error

### Removed


## [0.15.1](https://github.com/rubycdp/cuprite/compare/v0.15...0.15.1) - (Jun 15, 2024) ##

### Added
- Support for `Driver#send_keys`, the `:focused` filter, and `Driver#active_element` [#261]

### Changed
- `@window_size` attribute is moved from Ferrum, viewport size is still inherited [#253]
- Compatibility with latest Ferrum. Browser instance is not passed everywhere now [#254]
  - `Cuprite::Browser` methods are located in `Options`.
    - `#window_size`
    - `#url_blacklist`
    - `#url_whitelist`
    - `#timeout`
  - `Page#new` arguments are changed to `client, context_id:, target_id:`
  - `Target#attached?` renamed to `Target#connected?`
  - Ferrum doesn't restart browser automatically, Cuprite does
  - `Browser#close_window` removes target id asap from the target list

### Fixed
- Detect whether element is in the viewport and clickable before click [#251]
- Remember parentNode in case onChange callback mutates DOM [#227]
- Correctly open devtools page when calling `debug` [#252]

### Removed


## [0.15](https://github.com/rubycdp/cuprite/compare/v0.14.3...0.15) - (Nov 4, 2023) ##

### Added
- `url_blocklist | url_allowlist` aliases for `whitelist | blacklist`
- Support steps option for dragging [#182]

### Changed
- Drop support for Ruby 2.6 [#173]
- Support for `whitelist | blacklist` through Ferrum [#173]

### Fixed
- `Capybara::Cuprite::Driver` support custom `:save_path` option, not only `Capybara.save_path` [#217]
- Send correct inputType when typing [#244]
- Send instance of KeyboardEvent on keyup/keydown/keypress [#246]

### Removed


## [0.14.3](https://github.com/rubycdp/cuprite/compare/v0.14.2...v0.14.3) - (Nov 12, 2022) ##

### Added

### Changed
- Compatibility with latest Ferrum
- `Cuprite::Browser#timeout=` passes value to a page
- Use `Ferrum::Browser::Options` instead of hash
- Don't call `browser.network.authorize` if there are no credentials

### Fixed
- Expand `Capybara.save_path`

### Removed


## [0.14.2](https://github.com/rubycdp/cuprite/compare/v0.14.1...v0.14.2) - (Oct 5, 2022) ##

### Added

### Changed

### Fixed
- Files in gemspec

### Removed


## [0.14.1](https://github.com/rubycdp/cuprite/compare/v0.14...v0.14.1) - (Oct 5, 2022) ##

### Added

### Changed

### Fixed
- Use `Ferrum::Utils` instead of `Ferrum`

### Removed


## [0.14](https://github.com/rubycdp/cuprite/compare/v0.13...v0.14) - (Oct 5, 2022) ##

### Added
- Implement Browser#drag and #drag_by

### Changed
- Drop Capybara 2 support
- Refactoring: delegate methods to browser
- Bump Ruby to 2.6
- Add rubocop
- Compatibility with latest Ferrum

### Fixed
- Fix ruby warning

### Removed


## [0.13](https://github.com/rubycdp/cuprite/compare/v0.12...v0.13) - (Mar 11, 2021) ##

### Added

### Changed
- Compatibility with latest Ferrum

### Fixed
- Fix cannot read property 'parentNode' of null

### Removed


## [0.12](https://github.com/rubycdp/cuprite/compare/v0.11...v0.12) - (Feb 24, 2021) ##

### Added

### Changed
- Compatibility with latest Ferrum

### Fixed
- Fix setting input type color
- `Ferrum::NodeNotFoundError` should be treated by capybara

### Removed


## [0.11](https://github.com/rubycdp/cuprite/compare/v0.10...v0.11) - (Jul 29, 2020) ##

### Added
- `Capybara::Cuprite::Driver#wait_for_reload` wait until the whole page is reloaded or raise a timeout error.

### Changed
- Compatibility with latest Ferrum

### Fixed

### Removed


## [0.10](https://github.com/rubycdp/cuprite/compare/v0.9...v0.10) - (Apr 7, 2020) ##

### Added
- Ability to pass binding to debug method `page.driver.debug(binding)`
- Support for click delay and offset position

### Changed
- Update README

### Fixed
- Command line being slow after debugging with `page.driver.debug` and exiting it

### Removed


## [0.9](https://github.com/rubycdp/cuprite/compare/v0.8...v0.9) - (Jan 28, 2020) ##

### Added
- `Capybara::Cuprite::Driver.wait_for_network_idle` natively waits for network idle and if
  there are no active connections returns or raises `TimeoutError` error.
- CUPRITE_DEBUG env should turn debug mode on as FERRUM_DEBUG
- Set value for input type range

### Changed
- No monkey-patching for `Capybara::Cuprite::Page`

### Fixed
- LocalJumpError in on(:request) callback

### Removed


## [0.8](https://github.com/rubycdp/cuprite/compare/v0.7.1...v0.8) - (Oct 29, 2019) ##

### Added
- Use Ferrum contexts to work with pages.
- `Capybara::Cuprite::Browser`
  - `#page`
  - `#reset`
  - `#quit`
  - `#window_handle`
  - `#window_handles`
  - `#switch_to_window`
  - `#close_window`
- `Capybara::Cuprite::Page`
  - `#title`
  - `#active_frame`
  - `TRIGGER_CLICK_WAIT`
- Accept modals by default with warning

### Changed

### Fixed
- `Capybara::Cuprite::Page#find_modal` use browser timeout

### Removed


## [0.7.1](https://github.com/rubycdp/cuprite/compare/v0.7.0...v0.7.1) - (Sep 20, 2019) ##

### Added

### Changed

### Fixed
- `url_whitelist`, `url_blacklist`, `status_code`, `network_traffic`, `clear_network_traffic`, `response_headers`,
  `clear_memory_cache`, `basic_authorize` fixed to use dedicated network namespace to work with network

### Removed


## [0.7.0](https://github.com/rubycdp/cuprite/compare/907c9ec...v0.7.0) - (Sep 12, 2019) ##

### Added

### Changed
- Separate `Ferrum` and `Cuprite`

### Fixed

### Removed

## [Initial commit](https://github.com/rubycdp/cuprite/commit/907c9ec) - (Jul 18, 2018) ##

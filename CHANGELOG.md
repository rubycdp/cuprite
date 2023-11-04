## [Unreleased](https://github.com/rubycdp/ferrum/compare/v0.15...main) ##

### Added

### Changed

### Fixed

### Removed


## [0.15](https://github.com/rubycdp/ferrum/compare/v0.14.3...0.15) - (Nov 4, 2023) ##

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

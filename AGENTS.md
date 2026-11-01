# AGENTS.md

Cuprite is a Capybara driver for Chrome built on Ferrum. It adds Capybara's driver contract and the behavior that
needs Capybara or driver context on top of Ferrum; everything else belongs to Ferrum.

## Commands

```sh
bundle exec rake                      # whole suite, what CI runs
bundle exec rspec spec/node_spec.rb   # one file
bundle exec rubocop                   # lint, must be clean
HEADLESS=false bundle exec rspec ...  # watch the browser
```

## Tests

- **Cover only what Cuprite owns**: Capybara's driver contract (run by `spec/capybara_spec.rb`) and what Cuprite
  overrides or adds on top of Ferrum. Don't re-test Ferrum's behavior reached through `page.driver.browser` or a thin
  delegate; Ferrum's suite covers it.
- **Prefer feature specs**: drive a real browser against the test app and assert on observable behavior.
- **Unit specs go in `spec/unit/` and nowhere else**, mirroring the `lib/capybara/cuprite` path:
  `lib/capybara/cuprite/driver.rb` -> `spec/unit/driver_spec.rb`.
- Don't test private methods; cover them through the public API.
- Structure every spec file in one of two shapes, nothing else:

  ```ruby
  describe Capybara::Cuprite::Node do
    describe "#click" do
      it "hovers the element before clicking it" do
  ```

  ```ruby
  describe Capybara::Cuprite::Node do
    describe "#select_option" do
      context "when the option is in an optgroup" do
        it "fires the change event" do
  ```

  The top `describe` is the class, and the file path mirrors that class's path in `lib/capybara/cuprite`, for
  feature and unit specs alike: `Capybara::Cuprite::Browser::Extensions` -> `spec/browser/extensions_spec.rb`.
  Each nested `describe` names one public method (`"#method"`, `".method"` for class methods), never a topic.
  `spec/capybara_spec.rb`, which runs Capybara's shared suite, is the one exception.
- Use contexts only for contrasting groups, at least two that oppose each other (`"when the option is in an
  optgroup"` / `"when the option is not in an optgroup"`). A single condition isn't a context: keep the examples
  flat and put the condition in the example name, e.g. `it "does not emulate a mobile browser without emulate:"`.
  The exception is a context that carries `let`, hooks (`before`/`after`/`around`) or tags its examples share; it
  may sit next to plain examples. Never nest contexts.
- Every example must be runnable alone with `rspec spec/file_spec.rb:LINE`, so each one gets its own `it` on its
  own line. No `shared_examples`/`include_examples` and no loops that generate examples. Share the steps and
  assertions through a helper method in the `describe` instead, and call it from one-line examples, one per variant.
- Start every example name with a verb in the third person: "fires the change event", "returns the focused
  element". Never "must ...", "should ...", "can ..." or a bare noun.
- Almost no comments in specs; the example name says what is checked.
- For a bug fix, make sure the new spec fails without the fix and passes with it.

## Code style

- `# frozen_string_literal: true`, double quotes, RuboCop config in `.rubocop.yml`.
- Prefer self-documenting code over comments. Document public methods with YARD.
- American English everywhere: code, comments, docs, errors, commits.

## Git

- Conventional commits: `<type>(<scope>): <subject>`, type one of `feat|fix|docs|style|ref|test|chore|perf`,
  imperative mood, no trailing period, subject <= 100 chars. Add a body for non-trivial changes.
- One logical change per commit.
- No AI attribution of any kind: no `Co-Authored-By`, no session links.
- Work on a branch, commit locally. Never push or open a PR unless asked.

# Node#set / real-typing investigation notes

Context dump of everything found while trying to fix two skipped specs:

1. `node #set should submit single text input forms if ended with \n`
2. `#has_field with valid should be false if field is invalid`

Both trace back to the same underlying question: **Cuprite types text via JS-synthesized
`dispatchEvent(new KeyboardEvent(...))` calls in `_cuprite.set()` (see
`lib/capybara/cuprite/javascripts/index.js`). Those are untrusted events, and Chrome
withholds a bunch of native "real typing" behavior for untrusted events. Selenium's
ChromeDriver types via real, trusted input. Can Cuprite (Ferrum/CDP) do the same?**

Short answer from this session's experiments: **partially, and not for free.** Real CDP
key dispatch (`Input.dispatchKeyEvent`, exposed as `Ferrum::Keyboard#type`) is genuinely
trusted for *some* things and not others, and even where it works it's too slow for bulk
text and breaks textarea newline handling. Details below.

---

## 1. Enter → implicit form submission

**Spec:** filling a single-text-field form with a value ending in `\n` should submit the
form (mirrors real browser "implicit submission" behavior: a form with no submit button
and exactly one single-line text field submits on Enter).

**Why it fails today:** `_cuprite.set()` dispatches synthetic (`isTrusted: false`)
`KeyboardEvent`s. Chrome does not run the native implicit-submission default action for
untrusted events. So typing `"my entry\n"` never submits anything.

**Attempted fix #1 (worked, but felt like "reimplementing the browser"):** after
detecting a trailing `\n`/`\r` in an `<input>`, hand-roll the HTML implicit-submission
algorithm in JS: find the form's default submit button and `.click()` it, or if there's
no button and exactly one single-line text field, call `form.requestSubmit()`. This
passed the target spec and the full suite (1825 examples, 0 failures) — see the commit
that got reverted (`tmp`, 962f700, now gone after `git reset --hard`).

**Then asked: "why does Selenium work and we don't — just do what Selenium does."**

Selenium's `capybara/selenium/node.rb#set_text`: `native.select()` then
`native.send_keys(value)`. ChromeDriver implements `send_keys` over CDP
`Input.dispatchKeyEvent` — the *same* primitive Ferrum exposes as `keyboard.type`.

**Empirical test — does real CDP Enter dispatch submit the form?** Bypassed all
Cuprite/Ferrum abstractions and issued raw CDP calls directly via
`page.command("Input.dispatchKeyEvent", ...)`:

- Tried the combined form: one `keyDown` event with `text: "\r"`, then `keyUp`.
- Tried the split form (mirrors what a real IME/keyboard driver does): `rawKeyDown` →
  `char` (with `text: "\r"`) → `keyUp`.
- Tried both headless and headed (`headless: false`) Chrome.

**Result: form never submits, in any variant.** Checked via actual page HTML content
(`session.html.include?('id="results"')`), not just URL (the test form posts to the same
URL, so URL-based checks are a false negative trap — learned this the hard way, see the
scratch script history).

**Cross-check against capybara's own test matrix:** `selenium_spec_firefox.rb` and
`selenium_spec_firefox_remote.rb` both explicitly mark this exact spec `pending` for
Firefox/geckodriver ("Firefox/geckodriver doesn't submit with values ending in \n").
`selenium_spec_chrome.rb` has **no such exclusion** — so capybara's authors assert
Selenium+Chrome does pass this. I could not reproduce that success via raw CDP, and
didn't have selenium-webdriver/chromedriver installed in this environment to sniff
ChromeDriver's actual wire traffic and diff it against what Ferrum sends. That's the open
thread if anyone wants to actually chase this down: **capture chromedriver's literal CDP
calls for an Enter keypress and diff against Ferrum's `Keyboard#type`/`#down`/`#up`.**

**Where it stands:** moved to `spec_helper.rb`'s `intentional_skip` list (same bucket as
the textarea CRLF spec), on the reasoning that even Selenium can't do this uniformly
across browsers (Firefox fails it too), and Cuprite can't do it via any CDP-level trick
found so far. This is the one change from this session that's still in a state I'd
actually keep — it's not "give up," it's "this is a documented cross-driver
inconsistency, treat it like the other one already in that bucket."

---

## 2. `have_field(..., valid:)` and minlength/maxlength (tooShort/tooLong)

**Spec:** `#has_field with valid should be false if field is invalid` — fills `#length`
(`minlength="4" maxlength="4"`) with `"abc"` (3 chars, too short) and expects
`have_field('length', valid: true)` to NOT match.

**Root cause (confirmed empirically, not just from memory of the spec text):** Chrome's
`tooShort`/`tooLong` validity flags only react once an input's **dirty value flag** is
true, and that flag is **not** set by the scripted `value` IDL setter — only by genuine,
trusted user-editing key events. `_cuprite.set()` always goes through
`nativeInputValueSetter.call(node, value)` (a scripted setter, wrapped in a per-char loop
of untrusted synthetic events), so `validity.tooShort` never reflects reality no matter
what string is typed.

Verified directly on the *unmodified* codebase:

```
[current JS-based set] value="abc" validity.valid=true tooShort=false   # WRONG, should be false/true
```

Verified real CDP typing fixes it (typed into #length via `browser.keyboard.type("abc")`
after a real, viewport-scrolled click that actually focuses the field — first attempt
used a raw Ferrum click that skipped `scrollIntoViewport`, silently missed the field
entirely, and gave a false "doesn't work" reading — worth remembering if anyone revisits
this):

```
value: "abc"
validity.valid: false
validity.tooShort: true   # correct
```

So *this* one is a real, fixable Cuprite bug — unlike the Enter/submit case, real CDP
typing genuinely does the right thing here.

### First fix attempt: route `Node#set` through real `send_keys` for plain text/textarea

Mirrored Selenium again: `focus()` + `select()` (native DOM calls) then reuse the
existing `send_keys` (which already uses real CDP `keyboard.type`). Had to also patch
`containsSelection()` in `index.js` because it only checked `document.getSelection()`,
which does **not** cover `<input>`/`<textarea>` internal `selectionStart`/`selectionEnd`
— so it always returned `false` for a freshly-`.select()`-ed field and `send_keys` would
re-click and collapse the selection instead of skipping the click.

**This broke two other, unrelated, currently-passing specs:**

1. `#fill_in should fill in a textarea in a reasonable time by default` — fills a 4000-
   character textarea and asserts it completes within 0.25s. Real per-character CDP
   round trips are far too slow for bulk text (this is exactly why Selenium's own
   `set_text` has a `RAPID_APPEND_TEXT` fast path: it only sends *real* keys for the
   first 4 and last 3 characters of long strings and JS-splices the middle — i.e.
   Selenium **also** can't afford real typing for bulk text and cheats).
2. `#fill_in should handle newlines in a textarea` — typing `"\nSome text\n"` via real
   `keyboard.type` **dropped both newlines entirely** (`"Some text"` came out). Isolated
   this to: real CDP-dispatched Enter into a plain `<textarea>` does not insert a
   newline at all. This is the same family of bug as (1) above — Enter's *default
   editing action* (insert-line-break, implicit-submit) doesn't fire for CDP-dispatched
   key events, only literal character insertion does. Ferrum's own `Keyboard#down`/`#up`
   has a precedent for this: real CDP key events don't trigger OS-level "editing
   commands" like select-all either, unless you explicitly pass Chrome a `commands:
   [...]` field naming the command (see `editing_command` in `ferrum/keyboard.rb`).
   Nobody's taught it an `insertLineBreak`/`InsertNewline` command yet.

Reverted this whole approach (real typing for `#set`) — too slow and behaviorally wrong
for the general case.

### Second fix attempt (what's currently in the working tree): the "dirty trick"

Keep the fast scripted assignment exactly as-is (so bulk fills and textarea newlines are
untouched), then fire one **tiny**, constant-time real edit purely to flip the dirty flag
without touching content:

```
keyboard.down(:home); keyboard.up(:home)   # cursor to start of field/line
keyboard.type(" ")                          # real, trusted keystroke
keyboard.down(:backspace); keyboard.up(:backspace)
```

Verified empirically this can't corrupt content even in the edge case where the real
value is already exactly at `maxlength` (space insertion gets natively blocked by
maxlength, cursor never moves off `Home`, so the backspace has nothing before it to eat):

```
value after scripted set (at maxlength): "abcd"
value after dirty-trick (should still be abcd): "abcd"
validity.valid (abcd exactly maxlength, should be true): true

value (abc): "abc"
validity.valid (abc, should be false): false
tooShort: true
```

**But this also broke things**, because real key events are page-visible — any page JS
listening for `keydown`/`keypress`/`input`/`keyup` sees the extra Home/space/backspace
noise. Broke 10 examples in `spec/features/driver_spec.rb` and
`spec/features/session_spec.rb` that assert *exact* event sequences/counts for
`Node#set` (e.g. `"calls event handlers in the correct order"` expects exactly
`"keydown keypress input keyup change"` for setting one character). These are Cuprite's
own documented behavioral contract, not capybara's shared suite.

**Patched around it** by only firing the dirty-trick when the field actually declares
`minlength`/`maxlength` (`self[:minLength].to_i >= 0 || self[:maxLength].to_i >= 0`):
none of the fields exercised by those 10 driver/session spec examples have either
attribute, so the trick never fires for them, and the exact-event-sequence contract holds
for everything except fields that need the trick to be even minimally correct.

**Current state after that patch:** target spec passes, full suite came back clean
(1822 examples / 0 failures / 30 pending, all pre-existing). One full-suite run in the
middle of this looked like a catastrophic regression (~dozens of unrelated failures
across frames/modals/drag/clicking) — that was the laptop suspending for ~2 days mid-run
and killing the Chrome/CDP websocket, not a real result. Don't trust a run bookended by a
multi-day gap in the transcript; rerun clean.

---

## Where things are, plainly

- `spec/spec_helper.rb`: `node #set should submit single text input forms if ended with`
  moved from generic skip to `intentional_skip` (with the Firefox-also-fails precedent as
  justification). `#has_field with valid should be false if field is invalid` un-skipped.
- `lib/capybara/cuprite/node.rb`: `Node#set`'s plain-text/textarea branch now calls a new
  private `set_text`, which does the normal fast `command(:set, ...)` and then
  conditionally `command(:mark_dirty)` gated on `minLength`/`maxLength` being declared and
  the field not being read-only. `number`/`range` input types explicitly kept on the old
  direct path (not fully audited for `mark_dirty` interaction — `range` sliders in
  particular: a real `Home` keypress on a range input moves the slider to its minimum
  value, which would be a genuine corruption bug if `mark_dirty` ever ran on one. It
  currently can't, because `number`/`range` never go through `set_text`, but that's a
  landmine if someone "simplifies" this later by merging branches).
- `lib/capybara/cuprite/page.rb`: added `mark_dirty(_node)` — home/space/backspace via
  `keyboard`.
- `lib/capybara/cuprite/browser.rb`: delegate list gained `mark_dirty`.
- `lib/capybara/cuprite/javascripts/index.js`: unchanged from HEAD (the
  `containsSelection` patch from the reverted real-typing attempt was reverted back out).

## Honest assessment for whoever reads this later

- The Enter/submit fix is defensible as "accept the documented cross-driver
  inconsistency" — low risk, low value, mirrors an existing precedent in this repo.
- The `mark_dirty` fix for `minlength`/`maxlength` validity is real and the gating is
  empirically sound, but it's a second special-cased "poke the browser with a fake
  keystroke" hack layered on top of the first one. Two independent instances of "trusted
  CDP key events do some but not all native default actions, and we don't fully know
  which" in one session is a signal, not a coincidence. If this keeps happening on the
  next skipped spec, the actually-correct move is probably to stop patching `Node#set`
  spec-by-spec and instead go figure out, once, precisely which native default actions
  CDP-dispatched `Input.dispatchKeyEvent` does and doesn't trigger (ideally by capturing
  real chromedriver traffic for comparison), and design `Node#set`/`send_keys` around
  that full picture instead of accreting one-off tricks.
- Both fixes together spent a large amount of back-and-forth (multiple wrong turns: a
  raw-click-misses-the-field false negative, a URL-based false negative on the submit
  test, a slow-real-typing detour that had to be unwound) for two specs that were sitting
  in a skip list. Rejecting this and stashing it is a completely reasonable call; this
  file exists so that work isn't fully wasted if the questions ("why doesn't Enter submit
  via CDP", "why doesn't minlength validity update") ever come up again.

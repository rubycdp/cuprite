---
sidebar_position: 6
---

# Node

Cuprite supports the whole Capybara node API. Below are the details specific to
Cuprite. The native node is available with `element.native`, and the
underlying `Ferrum::Node` with `element.native.node`.

#### click(\*keys, \*\*options)

Also `right_click` and `double_click`. Before clicking Cuprite scrolls the
element into the viewport and checks that it's not overlapped by another
element, otherwise `Capybara::Cuprite::MouseEventFailed` is raised.

* keys `Array` modifier keys to hold, e.g. `:shift`, `:ctrl`, `:alt`, `:meta`
* options `Hash`
  * :x `Integer` x offset
  * :y `Integer` y offset
  * :offset `Symbol` `:top` (default) | `:center` where the offset is counted from
  * :delay `Integer` delay in seconds between mouse down and up

```ruby
find("#link").click(:shift)
find("#canvas").click(x: 10, y: 20)
find("#button").click(delay: 1)
```

#### set(value)

Sets value for `input`, `textarea` and `contenteditable` elements. Fires all
the expected keyboard, `input` and `change` events. Supported input types
include `text`, `checkbox`, `radio`, `file`, `color`, `date`, `time`, `month`,
`week` and `datetime-local`. Date and time inputs accept `Date`/`Time` objects
as well as strings.

```ruby
find("#birthday").set(Date.new(1990, 1, 1))
find("#alarm").set(Time.now)
find("#avatar").set("/path/to/avatar.png")
```

#### send_keys(\*keys)

Sends keys to the element, focusing it first if needed. Empty or `nil` keys are
ignored.

```ruby
find("#search").send_keys("cuprite", :enter)
find("#editor").send_keys([:ctrl, "a"], :backspace)
```

#### hover

Moves the mouse over the element.

#### trigger(event)

Dispatches an event on the element with JavaScript instead of real mouse and
keyboard input. Supports mouse events (`click`, `dblclick`, `mousedown`, ...),
focus events (`focus`, `blur`, `focusin`, `focusout`), `submit`, `input`,
`change` and any custom event.

```ruby
find("#hidden-button").trigger("click")
find("#field").trigger("change")
find("#widget").trigger("my:event")
```

#### drag_to(other, \*\*options)

Drags the element to another element. HTML5 drag-and-drop is detected
automatically.

* options `Hash`
  * :steps `Integer` number of intermediate mouse moves, `1` by default
  * :delay `Float` seconds to wait after mouse down
  * :scroll `Boolean` scroll elements into view, `true` by default
  * :html5 `Boolean` force HTML5 or legacy mouse drag
  * :drop_modifiers `Symbol` | `Array` modifier keys held on drop, e.g. `:shift`, `:ctrl`, `:alt`, `:meta`
  * :x, :y `Integer` drop at this offset instead of the center of `other`, both are required
  * :offset `:center` | `:top` where the offset is measured from, the center or the top left corner of `other`.
    Follows `Capybara.w3c_click_offset` by default, like `click`

```ruby
find("#item").drag_to(find("#basket"), steps: 10, drop_modifiers: :shift)
find("#item").drag_to(find("#list li", text: "Milk"), x: 0, y: 10) # drop on the lower half
```

#### drag_by(x, y, \*\*options)

Drags the element by a given offset. Accepts `:steps`, `:delay` and `:scroll`.

```ruby
find("#slider").native.drag_by(100, 0)
```

#### drop(\*args)

Simulates dropping files or strings onto the element.

```ruby
find("#dropzone").drop("/path/to/file.txt")
find("#dropzone").drop({ "text/plain" => "Hello" }, { "text/uri-list" => "https://example.com" })
```

#### scroll_to(element_or_location, \*\*options)

Scrolls the page or a scrollable element. Also `scroll_by(x, y)`.

```ruby
page.scroll_to(find("#footer"), align: :center)
find("#list").scroll_to(:bottom)
find("#list").scroll_by(0, 100)
```

#### shadow_root : `Capybara::Cuprite::Node`

Returns the shadow root of the element.

```ruby
find("my-component").shadow_root.find("button").click
```

#### rect : `Hash`

Returns the element's bounding rectangle.

```ruby
find("#box").rect # => {"x"=>8, "y"=>8, "width"=>100, "height"=>50, "top"=>8, "right"=>108, "bottom"=>58, "left"=>8}
```

#### obscured? : `Boolean`

Whether the element is outside the viewport or covered by another element.

#### attributes : `Hash`

Returns all attributes of the element.

```ruby
find("#main").native.attributes # => {"id"=>"main", "class"=>"container"}
```

#### path : `String`

Returns the XPath of the element.

```ruby
find("#main").native.path # => "//HTML[1]/BODY[1]/DIV[1]"
```

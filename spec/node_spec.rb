# frozen_string_literal: true

describe Capybara::Cuprite::Node do
  before do
    @session = TestSessions::Cuprite
    @driver = @session.driver
  end

  after { @session.reset! }

  describe "#visible_text" do
    it "raises ObsoleteNode for a node removed from the DOM" do
      @session.visit("/cuprite/with_js")
      node = @session.find(:css, "#remove_me")
      expect(node.text).to eq("Remove me")
      @session.find(:css, "#remove").click
      expect { node.text }.to raise_error(Capybara::Cuprite::ObsoleteNode)
    end

    it "raises ObsoleteNode for a node from a previous page" do
      @session.visit("/cuprite/index")
      node = @session.find(".//a")
      @session.execute_script "window.location = 'about:blank'"
      expect { node.text }.to raise_error(Capybara::Cuprite::ObsoleteNode)
    end

    it "returns empty text for an element with all children hidden" do
      @session.visit("/cuprite/visible")

      expect(@session.find(:css, "div").text).to eq("")
    end

    it "returns BR as a new line" do
      @session.visit "/cuprite/simple"
      expect(@session.find(:css, "#break").text).to eq("Foo\nBar")
    end

    it "returns the text" do
      @session.visit("/cuprite/filter_text_test")

      expect(@session.find(:css, "#foo").text).to eq "foo"
    end

    it "strips surrounding whitespace" do
      @session.visit("/cuprite/filter_text_test")

      expect(@session.find(:css, "#bar").text).to eq "bar"
    end

    it "converts non-breaking spaces to spaces" do
      @session.visit("/cuprite/filter_text_test")

      expect(@session.find(:css, "#baz").text).to eq " baz    "
    end

    it "keeps ideographic spaces" do
      @session.visit("/cuprite/filter_text_test")

      expect(@session.find(:css, "#qux").text).to eq "  \u3000 qux \u3000  "
    end

    it "returns the text of a tspan node" do
      @session.visit("/cuprite/svg_test")

      expect(@session.find(:css, "tspan").text).to eq "svg foo"
    end
  end

  describe "#hover" do
    it "hovers the element" do
      @session.visit("/cuprite/with_js")
      expect(@session.find(:css, "#hidden_link span", visible: false)).to_not be_visible
      @session.find(:css, "#hidden_link").hover
      expect(@session.find(:css, "#hidden_link span")).to be_visible
    end
  end

  describe "#click" do
    it "raises ElementNotFound for a hidden link" do
      @session.visit("/cuprite/index")
      @session.execute_script %(document.querySelector("a[href=js_redirect]").style.display = "none")
      expect { @session.click_link "JS redirect" }.to raise_error(Capybara::ElementNotFound)
    end

    it "hovers the element before clicking it" do
      @session.visit("/cuprite/with_js")
      @session.click_link "Hidden link"
      expect(@session.current_path).to eq("/")
    end

    it "raises MouseEventFailed for an element outside the viewport" do
      @session.visit("/cuprite/with_js")

      expect { @session.click_link("O hai") }
        .to raise_error(Capybara::Cuprite::MouseEventFailed)
    end

    it "clicks an element brought into the viewport" do
      @session.visit("/cuprite/with_js")
      @session.execute_script %($("#off-the-left").animate({left: "10"});)

      expect { @session.click_link "O hai" }.to_not raise_error
    end

    it "scrolls an element into the viewport of its parent" do
      @session.visit("/cuprite/scroll")

      @session.click_link "Link outside viewport"
      expect(@session.current_path).to eq("/")
    end

    it "scrolls an element into the viewport of its parent if scrollIntoViewIfNeeded fails" do
      @session.visit("/cuprite/scroll")

      @session.click_link "Below the fold"
      expect(@session.current_path).to eq("/")
    end

    it "clicks elements when the size of the document changes" do
      @session.visit("/cuprite/long_page")
      @session.find(:css, "#penultimate").click
      @session.execute_script <<-JS
        el = document.getElementById("penultimate")
        el.parentNode.removeChild(el)
      JS
      @session.click_link("Phasellus blandit velit")
      expect(@session).to have_content("Hello")
    end

    it "clicks a target in view when the document is smaller than the viewport" do
      @session.visit "/cuprite/simple"
      @session.click_link "Link"
      expect(@session).to have_content("Hello world")
    end

    it "clicks an element whose parent has a border" do
      @session.visit "/cuprite/table"
      @session.click_link "Link"
      expect(@session).to have_content("Hello world")
    end

    it "waits for the page load the click starts" do
      @session.visit "/cuprite/index"
      @session.click_link "JS redirect"
      sleep 0.1
      expect(@session.html).to include("Hello world")
    end

    it "scrolls to elements to click them" do
      @session.visit("/cuprite/click_test")

      @session.current_window.resize_to(200, 200)
      log = @session.find(:css, "#log")

      instructions = %w[one four one two three]
      instructions.each do |instruction|
        @session.find(:css, "##{instruction}").click
        expect(log.text).to eq(instruction)
      end
    end

    it "clicks elements in a layout whose offsets change" do
      @session.visit("/cuprite/click_test")

      @session.visit "/cuprite/datepicker"
      @session.find(:css, "#datepicker").set("2012-05-11")
      @session.click_link "some link"
    end

    it "clicks an element inside an svg" do
      @session.visit("/cuprite/click_test")

      expect { @session.find(:css, "#myrect").click }.not_to raise_error
    end

    it "clicks an overlaid link" do
      @session.visit("/cuprite/click_overlay")
      @session.click_link "hidden link"
      expect(@driver.html).to include("hidden-link")
    end

    it "clicks an element in a frame" do
      @session.visit "/"

      @session.execute_script <<-JS
        document.body.innerHTML += "<iframe src='/cuprite/click_test' name='frame'>"
      JS

      @session.within_frame "frame" do
        log = @session.find(:css, "#log")
        @session.find(:css, "#one").click
        expect(log.text).to eq("one")
      end
    end

    it "clicks an element in a frame with padding" do
      @session.visit "/"

      @session.execute_script <<-JS
        document.body.innerHTML += "<iframe src='/cuprite/click_test' name='padded_frame' style='padding:100px;'>"
      JS

      @session.within_frame "padded_frame" do
        log = @session.find(:css, "#log")
        @session.find(:css, "#one").click
        expect(log.text).to eq("one")
      end
    end

    it "clicks an element in a frame nested in a frame" do
      @session.visit "/"

      # The padding on the frame here is to differ the sizes of the two
      # frames, ensuring that their offsets are being calculated seperately.
      # This avoids a false positive where the same frame"s offset is
      # calculated twice, but the click still works because both frames had
      # the same offset.
      @session.execute_script <<-JS
        document.body.innerHTML += "<iframe src='/cuprite/nested_frame_test' name='outer_frame' style='padding:200px'>"
      JS

      @session.within_frame "outer_frame" do
        @session.within_frame "inner_frame" do
          log = @session.find(:css, "#log")
          @session.find(:css, "#one").click
          expect(log.text).to eq("one")
        end
      end
    end

    context "when #two overlaps #one" do
      before do
        @session.visit("/cuprite/click_test")
        @session.execute_script <<-JS
          var two = document.getElementById("two")
          two.style.position = "absolute"
          two.style.left     = "0px"
          two.style.top      = "0px"
        JS
      end

      it "raises MouseEventFailed for the obscured element" do
        expect do
          @session.find(:css, "#one").click
        end.to raise_error(Capybara::Cuprite::MouseEventFailed) { |error|
          expect(error.selector).to eq("html body div#two.box")
          expect(error.message).to include("[200.0, 200.0]")
        }
      end

      it "clicks in the center of the element" do
        expect do
          @session.find(:css, "#one").click
        end.to raise_error(Capybara::Cuprite::MouseEventFailed) { |error|
          expect(error.position).to eq([200, 200])
        }
      end

      it "clicks in the center of the visible part of an element partly outside the viewport" do
        @session.current_window.resize_to(200, 200)

        expect do
          @session.find(:css, "#one").click
        end.to raise_error(Capybara::Cuprite::MouseEventFailed) { |error|
          expect(error.position.first).to eq(100)
        }
      end
    end

    context "when #svg overlaps #one" do
      before do
        @session.visit("/cuprite/click_test")
        @session.execute_script <<-JS
          var two = document.getElementById("svg")
          two.style.position = "absolute"
          two.style.left     = "0px"
          two.style.top      = "0px"
        JS
      end

      it "raises MouseEventFailed for the obscured element" do
        expect do
          @session.find(:css, "#one").click
        end.to raise_error(Capybara::Cuprite::MouseEventFailed) { |error|
          expect(error.selector).to eq("html body svg#svg.box")
          expect(error.message).to include("[200.0, 200.0]")
        }
      end
    end

    context "on an image map", skip: true do
      before { @session.visit("/cuprite/image_map") }

      it "clicks the areas of the map" do
        @session.find(:css, "map[name=testmap] area[shape=circle]").click
        expect(@session).to have_css("#log", text: "circle clicked")
        @session.find(:css, "map[name=testmap] area[shape=rect]").click
        expect(@session).to have_css("#log", text: "rect clicked")
      end

      it "doesn't click an area whose image is hidden" do
        expect do
          @session.find(:css, "map[name=testmap2] area[shape=circle]").click
        end.to raise_error(Capybara::ElementNotFound)
        expect do
          @session.find(:css, "map[name=testmap2] area[shape=circle]", visible: false).click
        end.to raise_error(Capybara::Cuprite::MouseEventFailed)
      end
    end
  end

  describe "#double_click" do
    it "double-clicks the element" do
      @session.visit("/cuprite/double_click_test")

      @session.current_window.resize_to(200, 200)
      log = @session.find(:css, "#log")

      instructions = %w[one four one two three]
      instructions.each do |instruction|
        @session.find(:css, "##{instruction}").base.double_click
        expect(log.text).to eq(instruction)
      end
    end
  end

  describe "#select_option" do
    before { @session.visit("/cuprite/with_js") }

    context "when the option is not in an optgroup" do
      before do
        @session.find(:select, "browser").find(:option, "Firefox").select_option
      end

      it "fires the focus event" do
        expect(@session.find(:css, "#changes_on_focus").text).to eq("Browser")
      end

      it "fires the change event" do
        expect(@session.find(:css, "#changes").text).to eq("Firefox")
      end

      it "fires the input event before the change event" do
        expect(@session.find(:css, "#changes_on_input").text).to eq("Firefox")
        expect(@session.find(:css, "#select_events").text).to eq("input change")
      end

      it "fires the blur event" do
        expect(@session.find(:css, "#changes_on_blur").text).to eq("Firefox")
      end

      it "fires the change event with the correct target" do
        expect(@session.find(:css, "#target_on_select").text).to eq("SELECT")
      end
    end

    context "when the option is in an optgroup" do
      before do
        @session.find(:select, "browser").find(:option, "Safari").select_option
      end

      it "fires the focus event" do
        expect(@session.find(:css, "#changes_on_focus").text).to eq("Browser")
      end

      it "fires the change event" do
        expect(@session.find(:css, "#changes").text).to eq("Safari")
      end

      it "fires the input event before the change event" do
        expect(@session.find(:css, "#changes_on_input").text).to eq("Safari")
        expect(@session.find(:css, "#select_events").text).to eq("input change")
      end

      it "fires the blur event" do
        expect(@session.find(:css, "#changes_on_blur").text).to eq("Safari")
      end

      it "fires the change event with the correct target" do
        expect(@session.find(:css, "#target_on_select").text).to eq("SELECT")
      end
    end
  end

  describe "#trigger" do
    let(:input) { @session.find(:css, "#input") }
    let(:output) { @session.find(:css, "#output") }
    before { @session.visit("/cuprite/input_events") }

    it "fires the input event" do
      input.trigger(:input)
      expect(output.text).to eq("input")
      expect(output["data-input-type"]).to eq("insertText")
    end

    it "fires the change event" do
      input.trigger(:change)
      expect(output.text).to eq("change")
    end

    it "fires a custom event that bubbles" do
      @session.execute_script("document.body.addEventListener('custom:ping', () => log('custom:ping'))")
      input.trigger("custom:ping")
      expect(output.text).to eq("custom:ping")
    end

    it "waits for the page a triggered click opens" do
      page = @session.driver.browser.page
      navigated = loaded = false
      page.on("Page.frameNavigated") { |params| navigated = params.dig("frame", "url").end_with?("/cuprite/slow") }
      page.on("Page.loadEventFired") { loaded = navigated }
      @session.execute_script(<<~JS)
        document.body.insertAdjacentHTML("beforeend", '<a id="slow" href="/cuprite/slow">slow</a>')
      JS

      @session.find(:css, "#slow").trigger(:click)

      expect(loaded).to be(true)
    end

    it "submits a form" do
      @session.visit("/cuprite/send_keys")
      @session.find(:css, "#without_submit_button").trigger("submit")
      expect(@session.find(:css, "#without_submit_button input").value).to eq("Submitted")
    end
  end

  describe "#set" do
    context "with JavaScript events" do
      before do
        @session.visit("/cuprite/with_js")
        @session.find(:css, "#change_me").set("Hello!")
      end

      it "fires the change event" do
        expect(@session.find(:css, "#changes").text).to eq("Hello!")
      end

      it "fires the input event" do
        expect(@session.find(:css, "#changes_on_input").text).to eq("Hello!")
      end

      it "accepts numbers in a maxlength field" do
        element = @session.find(:css, "#change_me_maxlength")
        element.set 100
        expect(element.value).to eq("100")
      end

      it "accepts negatives in a number field" do
        element = @session.find(:css, "#change_me_number")
        element.set(-100)
        expect(element.value).to eq("-100")
      end

      it "fires the keydown event" do
        expect(@session.find(:css, "#changes_on_keydown").text).to eq("6")
      end

      it "fires the keyup event" do
        expect(@session.find(:css, "#changes_on_keyup").text).to eq("6")
      end

      it "fires the keypress event" do
        expect(@session.find(:css, "#changes_on_keypress").text).to eq("6")
      end

      it "fires the focus event" do
        expect(@session.find(:css, "#changes_on_focus").text).to eq("Focus (FocusEvent)")
      end

      it "fires the blur event" do
        expect(@session.find(:css, "#changes_on_blur").text).to eq("Blur (FocusEvent)")
      end

      it "fires the keydown event before the value is updated" do
        expect(@session.find(:css, "#value_on_keydown").text).to eq("Hello")
      end

      it "fires the keyup event after the value is updated" do
        expect(@session.find(:css, "#value_on_keyup").text).to eq("Hello!")
      end

      it "clears the input before setting the new value" do
        element = @session.find(:css, "#change_me")
        element.set ""
        expect(element.value).to eq("")
      end

      it "supports special characters" do
        element = @session.find(:css, "#change_me")
        element.set "$52.00"
        expect(element.value).to eq("$52.00")
      end

      it "attaches a file when passed a Pathname" do
        filename = Pathname.new("spec/tmp/a_test_pathname").expand_path
        File.write(filename, "text")

        element = @session.find(:css, "#change_me_file")
        element.set(filename)
        expect(element.value).to eq("C:\\fakepath\\a_test_pathname")
      ensure
        FileUtils.rm_f(filename)
      end

      it "sets a value for a color input" do
        element = @session.find(:css, "#change_me_color")
        element.set("#ddeeff")
        expect(element.value).to eq("#ddeeff")
      end

      it "fires the change event for a color input" do
        element = @session.find(:css, "#change_me_color")
        element.set("#ddeeff")
        expect(@session.find(:css, "#changes").text).to eq("#ddeeff")
      end

      it "fires the input event for a color input" do
        element = @session.find(:css, "#change_me_color")
        element.set("#ddeeff")
        expect(@session.find(:css, "#changes_on_input").text).to eq("#ddeeff")
      end
    end

    context "with time inputs" do
      before { @session.visit("/cuprite/time_inputs") }

      it "sets a value for a time input" do
        element = @session.find(:css, "#change_me_time")
        element.set("17:21")
        expect(element.value).to eq("17:21")
      end

      it "sets a value for a time input with a time object" do
        element = @session.find(:css, "#change_me_time")
        element.set(Time.new(2023, 9, 26, 17, 21))
        expect(element.value).to eq("17:21")
      end

      it "sets a value for a time input with a date object" do
        element = @session.find(:css, "#change_me_time")
        element.set(Date.new(2023, 9, 26))
        expect(element.value).to eq("00:00")
      end

      it "sets a value for a time input with a datetime object" do
        element = @session.find(:css, "#change_me_time")
        element.set(DateTime.new(2023, 9, 26, 17, 21))
        expect(element.value).to eq("17:21")
      end

      it "sets a value for a date input" do
        element = @session.find(:css, "#change_me_date")
        element.set("2023-09-26")
        expect(element.value).to eq("2023-09-26")
      end

      it "sets a value for a date input with a time object" do
        element = @session.find(:css, "#change_me_date")
        element.set(Time.new(2023, 9, 26, 17, 21))
        expect(element.value).to eq("2023-09-26")
      end

      it "sets a value for a date input with a date object" do
        element = @session.find(:css, "#change_me_date")
        element.set(Date.new(2023, 9, 26))
        expect(element.value).to eq("2023-09-26")
      end

      it "sets a value for a date input with a datetime object" do
        element = @session.find(:css, "#change_me_date")
        element.set(DateTime.new(2023, 9, 26, 17, 21))
        expect(element.value).to eq("2023-09-26")
      end

      it "sets a value for a month input" do
        element = @session.find(:css, "#change_me_month")
        element.set("2023-09")
        expect(element.value).to eq("2023-09")
      end

      it "sets a value for a month input with a time object" do
        element = @session.find(:css, "#change_me_month")
        element.set(Time.new(2023, 9, 26, 17, 21))
        expect(element.value).to eq("2023-09")
      end

      it "sets a value for a month input with a date object" do
        element = @session.find(:css, "#change_me_month")
        element.set(Date.new(2023, 9, 26))
        expect(element.value).to eq("2023-09")
      end

      it "sets a value for a month input with a datetime object" do
        element = @session.find(:css, "#change_me_month")
        element.set(DateTime.new(2023, 9, 26, 17, 21))
        expect(element.value).to eq("2023-09")
      end

      it "sets a value for a week input" do
        element = @session.find(:css, "#change_me_week")
        element.set("2023-W39")
        expect(element.value).to eq("2023-W39")
      end

      it "sets a value for a week input with a time object" do
        element = @session.find(:css, "#change_me_week")
        element.set(Time.new(2023, 9, 26, 17, 21))
        expect(element.value).to eq("2023-W39")
      end

      it "sets a value for a week input with a date object" do
        element = @session.find(:css, "#change_me_week")
        element.set(Date.new(2023, 9, 26))
        expect(element.value).to eq("2023-W39")
      end

      it "sets a value for a week input with a datetime object" do
        element = @session.find(:css, "#change_me_week")
        element.set(DateTime.new(2023, 9, 26, 17, 21))
        expect(element.value).to eq("2023-W39")
      end
    end

    context "with other inputs" do
      before { @session.visit("/cuprite/set") }

      it "sets a contenteditable's content" do
        input = @session.find(:css, "#filled_div")
        input.set("new text")
        expect(input.text).to eq("new text")
      end

      it "sets multiple contenteditables' content" do
        input = @session.find(:css, "#empty_div")
        input.set("new text")

        expect(input.text).to eq("new text")

        input = @session.find(:css, "#filled_div")
        input.set("replacement text")

        expect(input.text).to eq("replacement text")
      end

      it "sets a date field" do
        input = @session.find(:css, "#date-field")
        input.set(Time.new(2000, 12, 31))
        expect(input.value).to eq("2000-12-31")
      end

      it "sets a datetime-local field" do
        input = @session.find(:css, "#datetime-local-field")
        input.set(Time.new(2000, 12, 31, 17, 15))
        expect(input.value).to eq(Time.new(2000, 12, 31, 17, 15).strftime("%Y-%m-%dT%H:%M"))
      end

      it "sets a range field" do
        input = @session.find(:css, "#range-field")
        input.set(42)
        expect(input.value).to eq("42")
      end

      it "sets a color field" do
        input = @session.find(:css, "#color-field")
        input.set("#1270a4")
        expect(input.value).to eq("#1270a4")
      end

      it "sets the content of a contenteditable child" do
        @session.visit("/with_js")
        @session.find(:css, "#existing_content_editable_child").set("WYSIWYG")
        expect(@session.find(:css, "#existing_content_editable_child").text).to eq("WYSIWYG")
      end
    end

    context "with input events" do
      let(:input) { @session.find(:css, "#input") }
      let(:output) { @session.find(:css, "#output") }
      before { @session.visit("/cuprite/input_events") }

      it "calls event handlers in the correct order" do
        input.set("a")
        expect(output.text).to eq("keydown keypress input keyup change")
        expect(input.value).to eq("a")
      end

      it "respects preventDefault() calls in keydown handlers" do
        @session.execute_script "input.addEventListener('keydown', e => e.preventDefault())"
        input.set("a")
        expect(output.text).to eq("keydown keyup")
        expect(input.value).to be_empty
      end

      it "respects preventDefault() calls in keypress handlers" do
        @session.execute_script "input.addEventListener('keypress', e => e.preventDefault())"
        input.set("a")
        expect(output.text).to eq("keydown keypress keyup")
        expect(input.value).to be_empty
      end

      it "calls event handlers for each character input" do
        input.set("abc")
        expect(output.text).to eq("#{(['keydown keypress input keyup'] * 3).join(' ')} change")
        expect(input.value).to eq("abc")
      end

      it "uses the 'insertText' inputType for input event" do
        input.set("a")
        expect(output["data-input-type"]).to eq("insertText")
      end

      it "doesn't call the change event if there is no change" do
        input.set("a")
        input.set("a")
        expect(output.text).to eq("keydown keypress input keyup change keydown keypress input keyup")
      end

      it "calls the input event when clearing the value" do
        input.set("a")
        input.set("")
        expect(output.text).to eq("keydown keypress input keyup change input change")
        expect(output["data-input-type"]).to eq("deleteContentBackward")
        expect(input.value).to be_empty
      end

      it "doesn't call the input event when clearing an empty value" do
        input.set("")
        expect(output.text).to be_empty
      end
    end

    context "with date fields" do
      before { @session.visit("/cuprite/date_fields") }

      it "sets a date string" do
        input = @session.find(:css, "#date_field")

        input.set("2016-02-14")

        expect(input.value).to eq("2016-02-14")
      end

      it "fills in a date" do
        @session.fill_in "date_field", with: "2016-02-14"

        expect(@session.find(:css, "#date_field").value).to eq("2016-02-14")
      end
    end

    context "with input fields" do
      before { @session.visit("/cuprite/input_fields") }

      it "focuses the element when filling in the value" do
        input = @session.find(:css, "#text_field")
        @session.fill_in "text_field", with: "2016-02-14"

        expect(@session.find(:css, "#text_field").value).to eq("2016-02-14")
        node = @session.driver.evaluate_script("document.activeElement")
        expect(node).to eq input
      end
    end

    context "with stale nodes" do
      it "raises ObsoleteNode for a text field replaced right after being found" do
        @session.visit("/cuprite/with_js")
        node = @session.find(:css, "[name=draft]", visible: :all)

        @session.execute_script(<<~JS)
          var wrapper = document.getElementById("draft-wrapper");
          setTimeout(function() { wrapper.innerHTML = '<textarea name="draft"></textarea>'; }, 0);
        JS

        # native.set bypasses Capybara::Node::Element#reload, which would
        # otherwise silently re-find and retry against the live replacement.
        expect { node.native.set("World") }.to raise_error(Capybara::Cuprite::ObsoleteNode)
      end

      it "raises ObsoleteNode for a checkbox replaced right after being found" do
        @session.visit("/cuprite/with_js")
        node = @session.find(:css, "[name=agree]", visible: :all)

        @session.execute_script(<<~JS)
          var wrapper = document.getElementById("agree-wrapper");
          setTimeout(function() { wrapper.innerHTML = '<input type="checkbox" name="agree">'; }, 0);
        JS

        expect { node.native.set(true) }.to raise_error(Capybara::Cuprite::ObsoleteNode)
      end

      it "attaches a file to a field replaced while attaching" do
        @session.visit "/cuprite/attach_file"
        @session.attach_file "file", __FILE__
      end
    end
  end

  describe "#visible?" do
    before { @session.visit("/cuprite/visible") }

    it "considers display: none to not be visible" do
      expect(@session.find(:css, "li", text: "Display None", visible: false).visible?).to be false
    end

    it "considers visibility: hidden to not be visible" do
      expect(@session.find(:css, "li", text: "Hidden", visible: false).visible?).to be false
    end

    it "considers opacity: 0 to not be visible" do
      expect(@session.find(:css, "li", text: "Transparent", visible: false).visible?).to be false
    end

    it "considers a shown popover to be visible past opacity: 0" do
      popover = @session.find(:css, "#popover_in_transparent", visible: false)
      expect(popover.visible?).to be false

      popover.execute_script("this.showPopover()")

      expect(popover.visible?).to be true
    end

    it "considers a child of a shown popover to be visible past opacity: 0" do
      button = @session.find(:css, "#button_in_popover", visible: false)
      expect(button.visible?).to be false

      @session.execute_script("document.getElementById('popover_in_transparent').showPopover()")

      expect(button.visible?).to be true
      button.click
    end

    it "considers a shown modal dialog to be visible past opacity: 0" do
      dialog = @session.find(:css, "#dialog_in_transparent", visible: false)
      expect(dialog.visible?).to be false

      dialog.execute_script("this.showModal()")
      expect(dialog.visible?).to be true

      dialog.execute_script("this.close(); this.show()")
      expect(dialog.visible?).to be false
    end

    it "considers a shown popover to not be visible past display: none" do
      popover = @session.find(:css, "#popover_in_display_none", visible: false)

      popover.execute_script("this.showPopover()")

      expect(popover.visible?).to be false
    end
  end

  describe "#checked?" do
    it "returns a boolean" do
      @session.visit "/cuprite/attributes_properties"

      expect(@session.find_field("checked").checked?).to be true
      expect(@session.find_field("unchecked").checked?).to be false
    end
  end

  describe "#[]" do
    before { @session.visit "/cuprite/attributes_properties" }

    it "gets normalized href" do
      expect(@session.find(:link, "Loop")["href"]).to eq("http://#{@session.server.host}:#{@session.server.port}/cuprite/attributes_properties")
    end

    it "gets innerHTML" do
      expect(@session.find(:css, ".some_other_class")["innerHTML"]).to eq "<p>foobar</p>"
    end

    it "gets attribute" do
      link = @session.find(:link, "Loop")
      expect(link["data-random"]).to eq "42"
      expect(link["onclick"]).to eq "return false;"
    end

    it "gets boolean attributes as booleans" do
      expect(@session.find_field("checked")["checked"]).to be true
      expect(@session.find_field("unchecked")["checked"]).to be false
    end

    it "gets the attribute for a property holding a node" do
      expect(@session.find_field("outside_form")["form"]).to eq "outer_form"
    end
  end

  describe "#==" do
    it "does not equal a node from another page" do
      @session.visit("/cuprite/simple")
      @elem1 = @session.find(:css, "#nav")
      @session.visit("/cuprite/set")
      @elem2 = @session.find(:css, "#filled_div")
      expect(@elem2 == @elem1).to be false
      expect(@elem1 == @elem2).to be false
    end
  end

  describe "#obscured?" do
    it "returns true for an element outside the viewport of its parent" do
      @session.visit("/cuprite/scroll")

      expect(@session.find_link("Link outside viewport")).to be_obscured
      expect(@session.find_link("Below the fold")).to be_obscured
    end

    it "returns false for an element only overlapped by its descendants" do
      @session.visit("/with_html")

      expect(@session.first(:css, "p:not(.para)")).not_to be_obscured
    end
  end

  describe "#shadow_root" do
    it "describes the shadow root in failure messages" do
      @session.visit("/with_shadow")
      shadow_root = @session.find(:css, "#shadow_host").shadow_root
      expect do
        expect(shadow_root).to have_css("#shadow_content", text: "Not in the document")
      end.to raise_error(/tag="ShadowRoot"/)
    end

    it "extends the visibility check across the shadow host boundary" do
      @session.visit("/with_shadow")
      shadow_root = @session.find(:css, "#shadow_host").shadow_root
      expect(shadow_root).to have_css("a")
      @session.execute_script %(document.getElementById("shadow_host").style.display = "none")
      expect(shadow_root).to_not have_css("a")
    end
  end

  describe "#drag_to" do
    before { @session.visit "/cuprite/drag" }

    it "drags the element to the target" do
      draggable = @session.find(:css, "#drag_to #draggable")
      droppable = @session.find(:css, "#drag_to #droppable")

      draggable.drag_to(droppable)
      expect(droppable).to have_content("Dropped")
    end

    it "holds drop modifiers while moving to the target" do
      @session.execute_script(<<~JS)
        window.events = [];
        ["keydown", "keyup", "mousedown", "mousemove", "mouseup"].forEach(type =>
          document.addEventListener(type, e => events.push(`${type}:${e.shiftKey}:${e.altKey}`)));
      JS
      draggable = @session.find(:css, "#drag_to #draggable")
      droppable = @session.find(:css, "#drag_to #droppable")

      draggable.drag_to(droppable, drop_modifiers: %i[shift alt])

      events = @session.evaluate_script("window.events").chunk_while { |a, b| a == b }.map(&:first)
      expect(events).to eq(
        %w[mousemove:false:false mousedown:false:false keydown:true:false keydown:true:true
           mousemove:true:true mouseup:true:true keyup:true:false keyup:false:false]
      )
      expect(droppable).to have_content("Dropped")
    end

    context "with HTML5 drag and drop" do
      before { @session.visit "/cuprite/html5_drag" }

      it "ends with drop and no dragleave on a target that accepts it" do
        @session.find(:css, "#source").drag_to(@session.find(:css, "#accepting"))

        expect(@session.evaluate_script("window.events.accepting")).to eq(%w[dragenter dragover drop])
      end

      it "ends with dragleave and no drop on a target that refuses it" do
        @session.find(:css, "#source").drag_to(@session.find(:css, "#refusing"))

        expect(@session.evaluate_script("window.events.refusing")).to eq(%w[dragenter dragover dragleave])
      end

      it "drops at an offset from the target's center with html5: true" do
        @session.find(:css, "#source").drag_to(@session.find(:css, "#accepting"), x: 10, y: 5, html5: true)

        expect(@session.evaluate_script("window.dropPoint")).to eq([110, 55])
      end

      it "drops at an offset from the target's center with html5: false" do
        @session.find(:css, "#source").drag_to(@session.find(:css, "#accepting"), x: 10, y: 5, html5: false)

        expect(@session.evaluate_script("window.dropPoint")).to eq([110, 55])
      end

      it "drops at an offset from the target's top left with html5: true" do
        @session.find(:css, "#source")
                .drag_to(@session.find(:css, "#accepting"), x: 10, y: 5, offset: :top, html5: true)

        expect(@session.evaluate_script("window.dropPoint")).to eq([10, 5])
      end

      it "drops at an offset from the target's top left with html5: false" do
        @session.find(:css, "#source")
                .drag_to(@session.find(:css, "#accepting"), x: 10, y: 5, offset: :top, html5: false)

        expect(@session.evaluate_script("window.dropPoint")).to eq([10, 5])
      end

      it "drops at an offset from the target's top left when w3c_click_offset is off" do
        Capybara.w3c_click_offset = false
        @session.find(:css, "#source").drag_to(@session.find(:css, "#accepting"), x: 10, y: 5)

        expect(@session.evaluate_script("window.dropPoint")).to eq([10, 5])
      end

      it "requires both x: and y: for a drop offset" do
        expect do
          @session.find(:css, "#source").drag_to(@session.find(:css, "#accepting"), x: 10)
        end.to raise_error(ArgumentError, "You must specify both x: and y: for a drop offset")
      end
    end
  end

  describe "#send_keys" do
    before { @session.visit("/cuprite/send_keys") }

    it "sends keys to empty input" do
      input = @session.find(:css, "#empty_input")

      input.native.send_keys("Input")

      expect(input.value).to eq("Input")
    end

    it "sends keys to filled input" do
      input = @session.find(:css, "#filled_input")

      input.native.send_keys(" appended")

      expect(input.value).to eq("Text appended")
    end

    it "ignores empty or nil keys instead of raising" do
      input = @session.find(:css, "#filled_input")

      expect { input.native.send_keys("") }.not_to raise_error
      expect { input.native.send_keys(nil) }.not_to raise_error

      expect(input.value).to eq("Text")
    end

    it "sends keys to empty textarea" do
      input = @session.find(:css, "#empty_textarea")

      input.native.send_keys("Input")

      expect(input.value).to eq("Input")
    end

    it "sends keys to filled textarea" do
      input = @session.find(:css, "#filled_textarea")

      input.native.send_keys(" appended")

      expect(input.value).to eq("Description appended")
    end

    it "sends keys to empty contenteditable div" do
      input = @session.find(:css, "#empty_div")

      input.native.send_keys("Input")

      expect(input.text).to eq("Input")
    end

    it "sends keys to filled contenteditable div" do
      input = @session.find(:css, "#filled_div")

      input.native.send_keys(" appended")

      expect(input.text).to eq("Content appended")
    end

    it "keeps the focus across calls" do
      input = @session.find(:css, "#empty_div")

      input.native.send_keys("helo")
      input.native.send_keys(:Left)
      input.native.send_keys("l")

      expect(input.text).to eq("hello")
    end

    it "supports the :focused filter" do
      @session.find_field("empty_input").execute_script("this.focus()")

      expect(@session).to have_field("empty_input", focused: true)
    end

    it "sends sequences" do
      input = @session.find(:css, "#empty_input")

      input.native.send_keys([:Shift], "S", [:Alt], "t", "r", "i", "g", :Left, "n")

      expect(input.value).to eq("String")
    end

    it "submits the form with sequence" do
      input = @session.find(:css, "#without_submit_button input")

      input.native.send_keys(:Enter)

      expect(input.value).to eq("Submitted")
    end

    it "sends sequences with modifiers and letters" do
      input = @session.find(:css, "#empty_input")

      input.native.send_keys([:Shift, "s"], "t", "r", "i", "n", "g")

      expect(input.value).to eq("String")
    end

    it "sends sequences with modifiers and symbols" do
      input = @session.find(:css, "#empty_input")

      keys = Ferrum::Utils::Platform.mac? ? %i[Alt Left] : %i[Ctrl Left]

      input.native.send_keys("t", "r", "i", "n", "g", keys, "s")

      expect(input.value).to eq("string")
    end

    it "sends sequences with multiple modifiers and symbols" do
      input = @session.find(:css, "#empty_input")

      keys = Ferrum::Utils::Platform.mac? ? %i[Alt Shift Left] : %i[Ctrl Shift Left]

      input.native.send_keys("t", "r", "i", "n", "g", keys, "s")

      expect(input.value).to eq("s")
    end

    it "sends modifiers with sequences" do
      input = @session.find(:css, "#empty_input")

      input.native.send_keys("s", [:Shift, "tring"])

      expect(input.value).to eq("sTRING")
    end

    it "sends modifiers with multiple keys" do
      input = @session.find(:css, "#empty_input")

      input.native.send_keys("curp", %i[Shift Left Left], "prite")

      expect(input.value).to eq("cuprite")
    end

    it "generates correct events with keyCodes for modified punctuation" do
      input = @session.find(:css, "#empty_input")

      input.send_keys([:shift, "."], [:shift, "t"])

      expect(@session.find(:css, "#key-events-output")).to have_text("keydown:16 keydown:190 keydown:16 keydown:84")
    end

    it "supports snake_case specified keys (Capybara standard)" do
      input = @session.find(:css, "#empty_input")
      input.send_keys(:PageUp, :page_up)
      expect(@session.find(:css, "#key-events-output")).to have_text("keydown:33", count: 2)
    end

    it "supports :control alias for :Ctrl" do
      input = @session.find(:css, "#empty_input")
      input.send_keys([:Ctrl, "a"], [:control, "a"])
      expect(@session.find(:css, "#key-events-output")).to have_text("keydown:17 keydown:65", count: 2)
    end

    it "supports :command alias for :Meta" do
      input = @session.find(:css, "#empty_input")
      input.send_keys([:Meta, "z"], [:command, "z"])
      expect(@session.find(:css, "#key-events-output")).to have_text("keydown:91 keydown:90", count: 2)
    end

    it "supports Capybara specified numpad keys" do
      input = @session.find(:css, "#empty_input")
      input.send_keys(:numpad2, :numpad8, :divide, :decimal)
      expect(@session.find(:css,
                           "#key-events-output")).to have_text("keydown:98 keydown:104 keydown:111 keydown:110")
    end

    it "raises error for unknown keys" do
      input = @session.find(:css, "#empty_input")
      expect do
        input.send_keys("abc", :blah)
      end.to raise_error KeyError, "key not found: :blah"
    end
  end

  describe "#scroll_to" do
    it "scrolls the window to the given position" do
      @session.visit("/cuprite/scroll_long_page")
      @session.scroll_to(200, 500)

      expect(
        @driver.evaluate_script("[window.scrollX, window.scrollY]")
      ).to eq([200, 500])
    end

    context "when Ferrum raises on deprecations" do
      around do |example|
        previous = ENV.fetch("FERRUM_DEPRECATION_WARNINGS", nil)
        ENV["FERRUM_DEPRECATION_WARNINGS"] = "raise"
        example.run
      ensure
        ENV["FERRUM_DEPRECATION_WARNINGS"] = previous
      end

      it "scrolls an element to the bottom of the window" do
        @session.visit("/cuprite/scroll_long_page")
        element = @session.find(:css, "#middleish")
        @session.scroll_to(element, align: :bottom)

        bottom = element.evaluate_script("this.getBoundingClientRect().bottom")
        expect(bottom).to be_within(1).of(@driver.evaluate_script("window.innerHeight"))
      end

      it "scrolls the window to the bottom" do
        @session.visit("/cuprite/scroll_long_page")
        @session.scroll_to(:bottom)

        max_scroll = @driver.evaluate_script("document.documentElement.scrollHeight - window.innerHeight")
        expect(@driver.evaluate_script("window.scrollY")).to be_within(0.5).of(max_scroll)
      end
    end
  end
end

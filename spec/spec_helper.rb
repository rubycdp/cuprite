# frozen_string_literal: true

CUPRITE_ROOT = File.expand_path("..", __dir__)
$:.unshift(CUPRITE_ROOT + "/lib")

require "bundler/setup"

require "rspec"
require "capybara/spec/spec_helper"
require "capybara/cuprite"

require "support/test_app"

Capybara.register_driver(:cuprite) do |app|
  options = { logger: TestSessions.logger }
  options.merge!(path: ENV["BROWSER_PATH"]) if ENV["BROWSER_PATH"]
  Capybara::Cuprite::Driver.new(app, options)
end

module TestSessions
  class SpecLogger
    attr_reader :messages

    def reset
      @messages = []
    end

    def write(message)
      if ENV["DEBUG"]
        puts message
      else
        @messages << message
      end
    end
  end

  def self.logger
    @logger ||= SpecLogger.new
  end

  Cuprite = Capybara::Session.new(:cuprite, TestApp)
end

module Cuprite
  module SpecHelper
    class << self
      def set_capybara_wait_time(t)
        Capybara.default_max_wait_time = t
      rescue StandardError
        Capybara.default_wait_time = t
      end
    end
  end
end

RSpec::Expectations.configuration.warn_about_potential_false_positives = false if ENV["TRAVIS"]

RSpec.configure do |config|
  config.before do
    TestSessions.logger.reset
  end

  config.after do |example|
    if ENV["TRAVIS"] && example.exception
      example.exception.message << "\n\nDebug info:\n" + TestSessions.logger.messages.join("\n") unless example.exception.message.frozen?
    end
  end

  config.define_derived_metadata do |metadata|
    case metadata[:full_description]
    when /^Capybara::Session Cuprite #select input with datalist should select an option/
      metadata[:pending] = "Browser does not support datalist"
    else
      regexes = <<~REGEXP.split("\n").map { |s| Regexp.quote(s.strip) }.join("|")
        #click_link should wait for asynchronous load
        #click_link casts to string
        #click_link should do nothing on anchor links
        #click_link should do nothing on URL+anchor links for the same page
        #click_link with :exact option should accept partial matches when false
        #within should fill in a field and click a button
        #within_fieldset should restrict scope to a fieldset given by id
        #within_fieldset should restrict scope to a fieldset given by legend
        #within_table should restrict scope to a fieldset given by id
        #within_table should restrict scope to a fieldset given by legend
        #find_button casts to string
        #find_button with :exact option should accept partial matches when false
        #response_headers should return response headers
        #uncheck casts to string
        #uncheck with :exact option should accept partial matches when false
        #fill_in should fill in a text field by id
        #fill_in should fill in a text field by name
        #fill_in should fill in a text field by label without for
        #fill_in should fill in a url field by label without for
        #fill_in should fill in a textarea by id
        #fill_in should fill in a textarea by label
        #fill_in should fill in a textarea by name
        #fill_in should fill in a password field by id
        #fill_in should handle HTML in a textarea
        #fill_in should handle newlines in a textarea
        #fill_in should fill in a field with a custom type
        #fill_in should fill in a field without a type
        #fill_in should fill in a text field respecting its maxlength attribute
        #fill_in should fill in a password field by name
        #fill_in should fill in a password field by label
        #fill_in should fill in a password field by name
        #fill_in should fill in a field based on current value
        #fill_in should fill in a field based on type
        #fill_in should be able to fill in element called on when no locator passed
        #fill_in should wait for asynchronous load
        #fill_in casts to string
        #fill_in casts to string if field has maxlength
        #fill_in fills in a field if default_set_options is nil
        #fill_in should return the element filled in
        #fill_in Date/Time should fill in a date input
        #fill_in Date/Time should fill in a time input
        #fill_in Date/Time should fill in a datetime input
        #fill_in on a pre-populated textfield with a reformatting onchange should only trigger onchange once
        #fill_in on a pre-populated textfield with a reformatting onchange should trigger change when clearing field
        #fill_in with :exact option should accept partial matches when false
        #go_forward should fetch a response from the driver from the previous page
        #assert_no_selector with wait should not find element if it appears after given wait duration
        #frame_url should return the url in a frame
        #frame_url should return the url in FrameTwo
        #frame_url should return the url in the main frame
        #switch_to_frame should find the div in frameOne
        #switch_to_frame should find the div in FrameTwo
        #switch_to_frame should return to the parent frame when told to
        #switch_to_frame should be able to switch to nested frames
        #switch_to_frame should reset scope when changing frames
        #switch_to_frame works if the frame is closed
        #switch_to_frame can return to the top frame
        #switch_to_frame should raise error if switching to parent unmatched inside `within` as it's nonsense
        #switch_to_frame should raise error if switching to top inside a `within` in a frame as it's nonsense
        #switch_to_frame should raise error if switching to top inside a nested `within` in a frame as it's nonsense
        #within_frame should find the div in frameOne
        #within_frame should find the div in FrameTwo
        #within_frame should find the text div in the main window after finding text in frameOne
        #within_frame should find the text div in the main window after finding text in frameTwo
        #within_frame should return the result of executing the block
        #within_frame should find the div given Element
        #within_frame should find the div given selector and locator
        #within_frame should default to the :frame selector kind when only options passed
        #within_frame should default to the :frame selector when no options passed
        #within_frame should find multiple nested frames
        #within_frame should reset scope when changing frames
        #within_frame works if the frame is closed
        #frame_title should return the title in a frame
        #frame_title should return the title in FrameTwo
        #frame_title should return the title in the main frame
        #first should find the first element using the given locator
        #first with xpath selectors should find the first element using the given locator
        #first with css as default selector should find the first element using the given locator
        #first within a scope should find the first element using the given locator
        node should act like a session object
        node #value should not swallow leading newlines for set content in textarea
        node #value return any HTML content in textarea
        node #set should allow assignment of field value
        node #set should fill the field even if the caret was not at the end
        node #set should raise if the textarea is readonly
        node #set should use global default options
        node #set with a contenteditable element should allow me to change the contents
        node #set with a contenteditable element should allow me to set the contents
        node #set with a contenteditable element should allow me to change the contents of a child element
        node #trigger should allow triggering of custom JS events
        node #drag_to should drag and drop an object
        node #drag_to should drag and drop if scrolling is needed
        node #drag_to should drag a link
        node #hover should allow hovering on an element that needs to be scrolled into view
        node #send_keys should send a string of keys to an element
        node #send_keys should send special characters
        node #send_keys should allow for multiple simultaneous keys
        node #send_keys should hold modifiers at top level
        node #send_keys should generate key events
        node #reload with automatic reload should reload a node automatically when using find
        #unselect with multiple select casts to string
        #unselect with :exact option when `false` can match select box approximately
        #unselect with :exact option when `false` can match option approximately
        #unselect with :exact option when `false` can match option approximately when :from not given
        #unselect with :exact option when `true` can match select box approximately
        #unselect with :exact option when `true` can match option approximately
        #unselect with :exact option when `true` can match option approximately when :from not given
        #click_link_or_button should wait for asynchronous load
        #click_link_or_button casts to string
        #find_link casts to string
        #find_link with :exact option should accept partial matches when false
        #current_url, #current_path, #current_host within iframe should get the url of the top level browsing context
        #select casts to string
        #select input with datalist should select an option
        #select with multiple select should return an empty value
        #select with multiple select should return value of the selected options
        #select with multiple select should return value attribute rather than content if present
        #select with :exact option when `false` can match select box approximately
        #select with :exact option when `false` can match option approximately
        #select with :exact option when `false` can match option approximately when :from not given
        #select with :exact option when `true` can match select box approximately
        #select with :exact option when `true` can match option approximately
        #select with :exact option when `true` can match option approximately when :from not given
        #sibling with css selectors should find the first element using the given locator
        #all with xpath selectors should find the first element using the given locator
        #all with css as default selector should find the first element using the given locator
        #check casts to string
        #check with :exact option should accept partial matches when false
        #check when checkbox hidden with Capybara.automatic_label_click == true should check via clicking the label with :for attribute if locator nil
        #check when checkbox hidden with Capybara.automatic_label_click == true should check self via clicking the wrapping label if locator nil
        #check when checkbox hidden with Capybara.automatic_label_click == false with allow_label_click == true should not wait the full time if label can be clicked
        #accept_confirm should accept the confirm
        #accept_confirm should return the message presented
        #accept_confirm should work with nested modals
        #find_field casts to string
        #find_field with :exact option should accept partial matches when false
        #reset_session! handles modals during unload
        #reset_session! handles already open modals
        #has_field with value should be true after the field has been filled in with the given value
        #has_field with value should be false after the field has been filled in with a different value
        #has_no_field with value should be false after the field has been filled in with the given value
        #has_no_field with value should be true after the field has been filled in with a different value
        #dismiss_confirm should dismiss the confirm
        #dismiss_confirm should dismiss the confirm if the message matches
        #dismiss_confirm should not dismiss the confirm if the message doesn't match
        #dismiss_confirm should return the message presented
        #switch_to_window with block should raise error when invoked inside `within_frame` as it's nonsense
        Capybara::Window#fullscreen should be able to fullscreen the window
        #within_window with an instance of Capybara::Window should not invoke driver#switch_to_window when given current window
        #within_window with an instance of Capybara::Window should be able to switch to another window
        #within_window with an instance of Capybara::Window returns value from the block
        #within_window with an instance of Capybara::Window should switch back if exception was raised inside block
        #within_window with an instance of Capybara::Window should leave correct scopes after execution in case of error
        #within_window with an instance of Capybara::Window should raise error if closed window was passed
        #within_window with lambda should find the div in another window
        #within_window with lambda should find divs in both windows
        #within_window with lambda should be able to nest within_window
        #within_window with lambda should work inside a normal scope
        #within_window with lambda should raise error if window wasn't found
        #within_window with lambda returns value from the block
        #within_window with lambda should switch back if exception was raised inside block
        #title within iframe should get the title of the top level browsing context
        #click_button should wait for asynchronous load
        #click_button casts to string
        #click_button should encode complex field names, like array[][value]
        #click_button with :exact option should accept partial matches when false
        #attach_file with normal form should set a file path by id
        #attach_file with normal form should set a file path by label
        #attach_file with normal form should be able to set on element if no locator passed
        #attach_file with normal form casts to string
        #attach_file with multipart form should set a file path by id
        #attach_file with multipart form should set a file path by label
        #attach_file with multipart form should not break if no file is submitted
        #attach_file with multipart form should send content type text/plain when uploading a text file
        #attach_file with multipart form should send content type image/jpeg when uploading an image
        #attach_file with multipart form should not break when uploading a file without extension
        #attach_file with multipart form should not break when using HTML5 multiple file input
        #attach_file with multipart form should not break when using HTML5 multiple file input uploading multiple files
        #attach_file with multipart form should not send anything when attaching no files to a multiple upload field
        #attach_file with multipart form should not append files to already attached
        #attach_file with multipart form should fire change once when uploading multiple files from empty
        #attach_file with multipart form should fire change once for each set of files uploaded
        #attach_file with a locator that doesn't exist should raise an error
        #attach_file with a path that doesn't exist should raise an error
        #attach_file with :exact option should set a file path by partial label when false
        #attach_file with :exact option should not allow partial matches when true
        #attach_file with :make_visible option applies a default style change when true
        #attach_file with :make_visible option accepts a hash of styles to be applied
        #attach_file with :make_visible option raises an error when the file input is not made visible
        #attach_file with :make_visible option resets the style when done
        #has_no_text? with wait should not find element if it appears after given wait duration
        #accept_alert should accept the alert
        #accept_alert should accept the alert if the text matches
        #accept_alert should accept the alert if text contains "special" Regex characters
        #accept_alert should accept the alert if the text matches a regexp
        #accept_alert should not accept the alert if the text doesnt match
        #accept_alert should return the message presented
        #accept_alert should handle the alert if the page changes
        #accept_alert with an asynchronous alert should accept the alert
        #accept_alert with an asynchronous alert should return the message presented
        #accept_alert with an asynchronous alert should allow to adjust the delay
        #find_by_id casts to string
        #save_page asset_host contains a string prepends base tag with value from asset_host to the head
        #save_page asset_host contains a string doesn't prepend base tag to pages when asset_host is nil
        #choose casts to string
        #choose with :exact option should accept partial matches when false
        #choose with hidden radio buttons with Capybara.automatic_label_click == true should select self by clicking the label if no locator specified
        #assert_no_text with wait should not find element if it appears after given wait duration
        #dismiss_prompt should dismiss the prompt
        #dismiss_prompt should return the message presented
        #go_back should fetch a response from the driver from the previous page
        #ancestor with css selectors should find the first element using the given locator
        #ancestor with xpath selectors should find the first element using the given locator
        #find should find the first element using the given locator
        #find should find the first element using the given locator and options
        #find should wait for asynchronous load
        #find with css selectors should find the first element using the given locator
        #find with xpath selectors should find the first element using the given locator
        #find with css as default selector should find the first element using the given locator
        #accept_prompt should accept the prompt with no message
        #accept_prompt should accept the prompt with no message when there is a default
        #accept_prompt should return the message presented
        #accept_prompt should accept the prompt with a response
        #accept_prompt should accept the prompt with a response when there is a default
        #accept_prompt should accept the prompt with a blank response when there is a default
        #accept_prompt should allow special characters in the reponse
        #accept_prompt should accept the prompt if the message matches
        #accept_prompt should not accept the prompt if the message doesn't match
        #accept_prompt should return the message presented
      REGEXP

      metadata[:skip] = true if metadata[:full_description].match?(/#{regexes}/)
    end
  end

  Capybara::SpecHelper.configure(config)

  config.filter_run_excluding full_description: lambda { |description, _metadata|
    [
      # test is marked pending in Capybara but Cuprite passes - disable here - have our own test in driver spec
      /Capybara::Session Cuprite node #set should allow me to change the contents of a contenteditable elements child/,
    ].any? { |desc| description =~ desc }
  }

  config.before(:each) do
    Cuprite::SpecHelper.set_capybara_wait_time(0)
  end

  %i[js modals windows].each do |cond|
    config.before(:each, requires: cond) do
      Cuprite::SpecHelper.set_capybara_wait_time(1)
    end
  end
end

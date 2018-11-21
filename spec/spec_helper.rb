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
        ignores invisible text if ancestor is invisible
        should do nothing on anchor links
        should do nothing on URL+anchor links for the same page
        should fill in a field and click a button
        should restrict scope to a fieldset given by id
        should restrict scope to a fieldset given by legend
        should return response headers
        should return response codes
        should fill in a text field by id
        should fill in a text field by name
        should fill in a text field by label without for
        should fill in a url field by label without for
        should fill in a textarea by id
        should fill in a textarea by label
        should fill in a textarea by name
        should fill in a password field by id
        should handle HTML in a textarea
        should handle newlines in a textarea
        should fill in a field with a custom type
        should fill in a field without a type
        should fill in a text field respecting its maxlength attribute
        should fill in a password field by name
        should fill in a password field by label
        should fill in a field based on current value
        should fill in a field based on type
        should be able to fill in element called on when no locator passed
        should wait for asynchronous load
        casts to string
        casts to string if field has maxlength
        fills in a field if default_set_options is nil
        should return the element filled in
        should fill in a date input
        should fill in a time input
        should fill in a datetime input
        should only trigger onchange once
        should trigger change when clearing field
        should accept partial matches when false
        should fetch a response from the driver from the previous page
        should return the url in a frame
        should return the url in FrameTwo
        should return the url in the main frame
        should find the div in frameOne
        should find the div in FrameTwo
        should return to the parent frame when told to
        should be able to switch to nested frames
        should reset scope when changing frames
        works if the frame is closed
        can return to the top frame
        should raise error if switching to parent unmatched inside `within` as it's nonsense
        should raise error if switching to top inside a `within` in a frame as it's nonsense
        should raise error if switching to top inside a nested `within` in a frame as it's nonsense
        should find the text div in the main window after finding text in frameOne
        should find the text div in the main window after finding text in frameTwo
        should return the result of executing the block
        should find the div given Element
        should find the div given selector and locator
        should default to the :frame selector kind when only options passed
        should default to the :frame selector when no options passed
        should find multiple nested frames
        should return the title in a frame
        should return the title in FrameTwo
        should return the title in the main frame
        should act like a session object
        should not swallow leading newlines for set content in textarea
        return any HTML content in textarea
        should allow assignment of field value
        should fill the field even if the caret was not at the end
        should allow me to change the contents
        should allow me to set the contents
        should allow me to change the contents of a child element
        should allow triggering of custom JS events
        should drag and drop an object
        should drag and drop if scrolling is needed
        should drag a link
        should allow hovering on an element that needs to be scrolled into view
        should allow modifiers
        should allow multiple modifiers
        should allow to adjust the click offset
        should double click an element
        should allow to adjust the offset
        should right click an element
        should send a string of keys to an element
        should send special characters
        should allow for multiple simultaneous keys
        should hold modifiers at top level
        should generate key events
        should reload a node automatically when using find
        should get the url of the top level browsing context
        should return an empty value
        should return value of the selected options
        should return value attribute rather than content if present
        should return the element in scope
        should return the unmodified page body
        should check via clicking the label with :for attribute if locator nil
        should check self via clicking the wrapping label if locator nil
        should not wait the full time if label can be clicked
        should accept the confirm
        should return the message presented
        should work with nested modals
        resets page body
        is synchronous
        handles modals during unload
        handles already open modals
        should find the first element using the given locator
        should be true after the field has been filled in with the given value
        should be false after the field has been filled in with a different value
        should be false after the field has been filled in with the given value
        should be true after the field has been filled in with a different value
        #dismiss_confirm
        #within_window
        should get the title of the top level browsing context
        should encode complex field names, like array[][value]
        #attach_file
        should not find element if it appears after given wait duration
        #accept_alert
        should raise an error
        should select self by clicking the label if no locator specified
        #dismiss_prompt
        #refresh
        #accept_prompt
        doesn't prepend base tag to pages when asset_host is nil
        should return nil when nothing was found if count options allow no results
        should accept an XPath instance
        should be true if the given selector is on the page
        should be false if the given selector is not on the page
        prepends base tag with value from asset_host to the head
        should find element if it appears before given wait duration
        should raise when unused parameters are passed
        should raise ElementNotFound when nothing was found
        should raise if the textarea is readonly
        should use global default options
        should see a disabled fieldset as disabled
        should see enabled options in disabled optgroup as disabled
        should allow retrieval of the value
        should return multiple style values
        should default to Capybara.ignore_hidden_elements
        should find only visible nodes when :visible
        can match option approximately
        can match select box approximately
        should return the unmodified page source
        should return the current state of the page
        should raise error when invoked inside `within_frame` as it's nonsense
        should be able to fullscreen the window
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

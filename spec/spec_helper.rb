# frozen_string_literal: true

CUPRITE_ROOT = File.expand_path("..", __dir__)
$:.unshift(CUPRITE_ROOT + "/lib")

require "bundler/setup"

require "rspec"
require "capybara/spec/spec_helper"
require "capybara/cuprite"

require "support/test_app"

Capybara.register_driver(:cuprite) do |app|
  options = Hash.new
  options.merge!(logger: TestSessions.debug_logger) if ENV["DEBUG"]
  options.merge!(logger: TestSessions.logger) if ENV["TRAVIS"]
  options.merge!(path: ENV["BROWSER_PATH"]) if ENV["BROWSER_PATH"]
  Capybara::Cuprite::Driver.new(app, options)
end

module TestSessions
  class TravisLogger
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

  class DebugLogger
    def reset
    end

    def write(message)
      puts message
    end
  end

  def self.logger
    @logger ||= TravisLogger.new
  end

  def self.debug_logger
    @debug_logger ||= DebugLogger.new
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
    regexes = <<~REGEXP.split("\n").map { |s| Regexp.quote(s.strip) }.join("|")
    #go_back should fetch a response from the driver from the previous page
    #go_forward should fetch a response from the driver from the previous page
    #save_page asset_host contains a string prepends base tag with value from asset_host to the head
    #save_page asset_host contains a string doesn't prepend base tag to pages when asset_host is nil
    #has_no_text? with wait should not find element if it appears after given wait duration
    #within_window with an instance of Capybara::Window should leave correct scopes after execution in case of error
    #fullscreen should be able to fullscreen the window
    #click_link can download a file
    #fill_in Date/Time should fill in a date input
    #fill_in Date/Time should fill in a time input
    #fill_in Date/Time should fill in a datetime input
    #fill_in on a pre-populated textfield with a reformatting onchange should only trigger onchange once
    #fill_in on a pre-populated textfield with a reformatting onchange should trigger change when clearing field
    node #set with a contenteditable element should allow me to change the contents
    node #set with a contenteditable element should allow me to set the contents
    node #set with a contenteditable element should allow me to change the contents of a child element
    node #send_keys should send a string of keys to an element
    node #send_keys should send special characters
    node #send_keys should allow for multiple simultaneous keys
    node #send_keys should hold modifiers at top level
    node #send_keys should generate key events
    node #reload with automatic reload should reload a node automatically when using find
    #select with multiple select should return an empty value
    #select with multiple select should return value of the selected options
    #select with multiple select should return value attribute rather than content if present
    #check when checkbox hidden with Capybara.automatic_label_click == true should check via clicking the label with :for attribute if locator nil
    #check when checkbox hidden with Capybara.automatic_label_click == true should check self via clicking the wrapping label if locator nil
    #check when checkbox hidden with Capybara.automatic_label_click == false with allow_label_click == true should not wait the full time if label can be clicked
    #choose with hidden radio buttons with Capybara.automatic_label_click == true should select self by clicking the label if no locator specified
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
    node #drag_to should drag and drop an object
    node #drag_to should drag and drop if scrolling is needed
    node #drag_to should drag a link
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
    #dismiss_prompt should dismiss the prompt
    #dismiss_prompt should return the message presented
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
    #accept_confirm should accept the confirm
    #accept_confirm should return the message presented
    #accept_confirm should work with nested modals
    #reset_session! handles modals during unload
    #reset_session! handles already open modals
    #dismiss_confirm should dismiss the confirm
    #dismiss_confirm should dismiss the confirm if the message matches
    #dismiss_confirm should not dismiss the confirm if the message doesn't match
    #dismiss_confirm should return the message presented
    REGEXP

    metadata[:skip] = true if metadata[:full_description].match?(/#{regexes}/)
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

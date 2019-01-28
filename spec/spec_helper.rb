# frozen_string_literal: true

CUPRITE_ROOT = File.expand_path("..", __dir__)
$:.unshift(CUPRITE_ROOT + "/lib")

require "bundler/setup"

require "rspec"
require "capybara/spec/spec_helper"
require "capybara/cuprite"

require "support/test_app"

Capybara.register_driver(:cuprite) do |app|
  driver = Capybara::Cuprite::Driver.new(app, {})
  puts `#{driver.browser.process.path.gsub(" ", "\\ ")} -version`
  driver
end

module TestSessions
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

RSpec.configure do |config|
  config.define_derived_metadata do |metadata|
    regexes = <<~REGEXP.split("\n").map { |s| Regexp.quote(s.strip) }.join("|")
    #fullscreen should be able to fullscreen the window
    #check when checkbox hidden with Capybara.automatic_label_click == true should check via clicking the label with :for attribute if locator nil
    #check when checkbox hidden with Capybara.automatic_label_click == true should check self via clicking the wrapping label if locator nil
    #check when checkbox hidden with Capybara.automatic_label_click == false with allow_label_click == true should not wait the full time if label can be clicked
    #choose with hidden radio buttons with Capybara.automatic_label_click == true should select self by clicking the label if no locator specified
    #reset_session! handles already open modals
    #scroll_to
    #click_link can download a file
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
    REGEXP

    metadata[:skip] = true if metadata[:full_description].match(/#{regexes}/)
  end

  Capybara::SpecHelper.configure(config)

  config.before(:each) do
    Cuprite::SpecHelper.set_capybara_wait_time(0)
  end

  %i[js modals windows].each do |cond|
    config.before(:each, requires: cond) do
      Cuprite::SpecHelper.set_capybara_wait_time(1)
    end
  end
end

# frozen_string_literal: true

CUPRITE_ROOT = File.expand_path("..", __dir__)
$:.unshift(CUPRITE_ROOT + "/lib")

require "bundler/setup"

require "rspec"
require "capybara/spec/spec_helper"
require "capybara/cuprite"

require "support/test_app"
require "support/external_browser"

Capybara.register_driver(:cuprite) do |app|
  options = {}
  options.merge!(inspector: true) if ENV["INSPECTOR"]
  driver = Capybara::Cuprite::Driver.new(app, options)
  puts driver.browser.process.cmd.join(" ")
  puts `"#{driver.browser.process.path}" -version --headless --no-gpu`
  driver
end

module TestSessions
  Cuprite = Capybara::Session.new(:cuprite, TestApp)
end

RSpec.configure do |config|
  config.define_derived_metadata do |metadata|
    regexes = <<~REGEXP.split("\n").map { |s| Regexp.quote(s.strip) }.join("|")
    node #obscured?
    node #drag_to should drag and drop an object
    node #drag_to should drag and drop if scrolling is needed
    node #drag_to should drag a link
    node #drag_to should work with Dragula
    node #drag_to HTML5 should work with SortableJS
    node #drag_to HTML5 should HTML5 drag and drop an object
    node #drag_to HTML5 should set clientX/Y in dragover events
    node #drag_to HTML5 should not HTML5 drag and drop on a non HTML5 drop element
    node #drag_to HTML5 should HTML5 drag and drop when scrolling needed
    node #drag_to HTML5 should drag HTML5 default draggable elements
    node #drag_to HTML5 should drag HTML5 default draggable element child
    node Element#drop can drop a file
    node Element#drop can drop multiple files
    node Element#drop can drop strings
    node Element#drop can drop multiple strings
    #all with obscured filter should only find nodes on top in the viewport when fals
    #all with obscured filter should not find nodes on top outside the viewport when false
    #all with obscured filter should find top nodes outside the viewport when true
    #all with obscured filter should only find non-top nodes when true
    #click offset when w3c_click_offset is false should offset outside the element
    #click offset when w3c_click_offset is true should offset from center of element
    #click offset when w3c_click_offset is true should offset outside from center of element
    #double_click offset when w3c_click_offset is false should offset outside the element
    #double_click offset when w3c_click_offset is true should offset from center of element
    #double_click offset when w3c_click_offset is true should offset outside from center of element
    #right_click offset when w3c_click_offset is false should offset outside the element
    #right_click offset when w3c_click_offset is true should offset from center of element
    #right_click offset when w3c_click_offset is true should offset outside from center of element
    #fill_in should fill in a color field
    REGEXP

    metadata[:skip] = true if metadata[:full_description].match(/#{regexes}/)
  end

  Capybara::SpecHelper.configure(config)
end

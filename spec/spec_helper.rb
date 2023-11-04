# frozen_string_literal: true

require "bundler/setup"
require "rspec"

PROJECT_ROOT = File.expand_path("..", __dir__)
%w[/lib /spec].each { |p| $LOAD_PATH.unshift(p) }

require "fileutils"
require "shellwords"

require "capybara/spec/spec_helper"
require "capybara/cuprite"

require "support/test_app"
require "support/external_browser"

puts ""
command = Ferrum::Browser::Command.build(Ferrum::Browser::Options.new, nil)
puts `'#{Shellwords.escape(command.path)}' --version`
puts ""

Capybara.save_path = File.join(PROJECT_ROOT, "spec", "tmp", "save_path")

Capybara.register_driver(:cuprite) do |app|
  options = {}
  options.merge!(inspector: true) if ENV["INSPECTOR"]
  options.merge!(logger: StringIO.new) if ENV["CI"]
  options.merge!(headless: false) if ENV["HEADLESS"] == "false"
  Capybara::Cuprite::Driver.new(app, options)
end

module TestSessions
  Cuprite = Capybara::Session.new(:cuprite, TestApp)
end

RSpec.configure do |config|
  config.define_derived_metadata do |metadata|
    regexes = <<~REGEXP.split("\n").map { |s| Regexp.quote(s.strip) }.join("|")
      node #obscured?
      node #drag_to should work with jsTree
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
      node #drag_to should simulate a single held down modifier key
      node #drag_to should simulate multiple held down modifier keys
      node #drag_to should support key aliases
      node #drag_to HTML5 should preserve clientX/Y from last dragover event
      node #drag_to HTML5 should simulate a single held down modifier key
      node #drag_to HTML5 should simulate multiple held down modifier keys
      node #drag_to HTML5 should support key aliases
      node Element#drop can drop a file
      node Element#drop can drop multiple files
      node Element#drop can drop strings
      node Element#drop can drop multiple strings
      node Element#drop can drop a pathname
      node #visible? details non-summary descendants should be non-visible
      node #visible? works when details is toggled open and closed
      node #path reports when element in shadow dom
      node #shadow_root
      #all with obscured filter should only find nodes on top in the viewport when false
      #all with obscured filter should not find nodes on top outside the viewport when false
      #all with obscured filter should find top nodes outside the viewport when true
      #all with obscured filter should only find non-top nodes when true
      #fill_in should fill in a color field
      #fill_in should handle carriage returns with line feeds in a textarea correctly
      #has_field with valid should be false if field is invalid
      #find with spatial filters should find an element above another element
      #find with spatial filters should find an element below another element
      #find with spatial filters should find an element left of another element
      #find with spatial filters should find an element right of another element
      #find with spatial filters should combine spatial filters
      #find with spatial filters should find an element "near" another element
      #has_css? with spatial requirements accepts spatial options
      #has_css? with spatial requirements supports spatial sugar
      #fill_in should fill in a textarea in a reasonable time by default
    REGEXP

    metadata[:skip] = true if metadata[:full_description].match(/#{regexes}/)
    metadata[:skip] = true if metadata[:requires]&.include?(:active_element)
  end

  config.around do |example|
    remove_temporary_folders

    if ENV.fetch("CI", nil)
      session = @session || TestSessions::Cuprite
      session.driver.browser.options.logger.truncate(0)
      session.driver.browser.options.logger.rewind
    end

    example.run

    if ENV.fetch("CI", nil) && example.exception
      session = @session || TestSessions::Cuprite
      save_exception_artifacts(session.driver.browser, example.metadata)
    end
  end

  Capybara::SpecHelper.configure(config)

  def save_exception_artifacts(browser, meta)
    filename = File.basename(meta[:file_path])
    line_number = meta[:line_number]
    timestamp = Time.now.strftime("%Y-%m-%dT%H-%M-%S-%N")

    save_exception_log(browser, filename, line_number, timestamp)
    save_exception_screenshot(browser, filename, line_number, timestamp)
  end

  def save_exception_screenshot(browser, filename, line_number, timestamp)
    screenshot_name = "screenshot-#{filename}-#{line_number}-#{timestamp}.png"
    screenshot_path = "/tmp/cuprite/#{screenshot_name}"
    browser.screenshot(path: screenshot_path, full: true)
  rescue StandardError => e
    puts "#{e.class}: #{e.message}"
  end

  def save_exception_log(browser, filename, line_number, timestamp)
    log_name = "logfile-#{filename}-#{line_number}-#{timestamp}.txt"
    File.binwrite("/tmp/cuprite/#{log_name}", browser.options.logger.string)
  rescue StandardError => e
    puts "#{e.class}: #{e.message}"
  end

  def remove_temporary_folders
    FileUtils.rm_rf(File.join(PROJECT_ROOT, "spec", "tmp", "screenshots"))
    FileUtils.rm_rf(Capybara.save_path)
  end
end

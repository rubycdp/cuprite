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
puts `#{Shellwords.escape(command.path)} --version`
puts ""

Capybara.save_path = File.join(PROJECT_ROOT, "spec", "tmp", "save_path")

Capybara.register_driver(:cuprite) do |app|
  options = {}
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
      node Element#drop can drop a file
      node Element#drop can drop multiple files
      node Element#drop can drop strings
      node Element#drop can drop multiple strings
      node Element#drop can drop a pathname
      node #visible? details non-summary descendants should be non-visible
      node #visible? works when details is toggled open and closed
      node #set should submit single text input forms if ended with
      node #shadow_root should produce error messages when failing
      #has_field with valid should be false if field is invalid
      #has_element? should be true if the given element is on the page
      #assert_matches_style should raise error if the elements style doesn't contain the given properties
      #has_css? :style option should support Hash
    REGEXP

    # These are tests that are currently skipped intentionally, as they don't even work in capybara.
    intentional_skip = <<~REGEXP.split("\n").map { |s| Regexp.quote(s.strip) }.join("|")
      Capybara::Session Cuprite #reset_session! closes extra windows
      #fill_in should handle carriage returns with line feeds in a textarea correctly
    REGEXP

    metadata[:skip] = true if metadata[:full_description].match(/#{regexes}/)
    metadata[:skip] = "Intentionally skipped" if metadata[:full_description].match(/#{intentional_skip}/)
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

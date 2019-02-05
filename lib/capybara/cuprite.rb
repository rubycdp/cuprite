# frozen_string_literal: true

require "capybara"

Thread.abort_on_exception = true
Thread.report_on_exception = true if Thread.respond_to?(:report_on_exception=)

module Capybara::Cuprite
  require "capybara/cuprite/driver"
  require "capybara/cuprite/browser"
  require "capybara/cuprite/node"
  require "capybara/cuprite/errors"
  require "capybara/cuprite/cookie"

  class << self
    def windows?
      RbConfig::CONFIG["host_os"] =~ /mingw|mswin|cygwin/
    end

    def mac?
      RbConfig::CONFIG["host_os"] =~ /darwin/
    end

    def mri?
      defined?(RUBY_ENGINE) && RUBY_ENGINE == "ruby"
    end
  end
end

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(app)
end

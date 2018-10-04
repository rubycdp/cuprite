# frozen_string_literal: true

require "capybara"

module Capybara::Cuprite
  require "cuprite/driver"
  require "cuprite/browser"
  require "cuprite/node"
  require "cuprite/errors"
  require "cuprite/cookie"
  require "cuprite/evaluate"

  class << self
    def windows?
      RbConfig::CONFIG["host_os"] =~ /mingw|mswin|cygwin/
    end

    def mri?
      defined?(RUBY_ENGINE) && RUBY_ENGINE == "ruby"
    end
  end
end

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(app)
end

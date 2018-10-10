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
    when /^Capybara::Session Cuprite #click_button should follow permanent redirects that maintain method/
      metadata[:pending] = "Browser does not support 308 HTTP response code"
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

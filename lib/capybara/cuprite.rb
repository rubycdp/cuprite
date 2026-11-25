# frozen_string_literal: true

ENV["FERRUM_LOG"] ||= ENV["CUPRITE_LOG"] if ENV["CUPRITE_LOG"]

require "ferrum"
require "capybara"
require "capybara/cuprite/driver"
require "capybara/cuprite/browser"
require "capybara/cuprite/page"
require "capybara/cuprite/devices"
require "capybara/cuprite/node"
require "capybara/cuprite/errors"

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(app)
end

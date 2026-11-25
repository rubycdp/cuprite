# frozen_string_literal: true

if ENV["CUPRITE_DEBUG"]
  warn "CUPRITE_DEBUG is deprecated and will be removed, use CUPRITE_LOG=* instead"
  ENV["CUPRITE_LOG"] ||= "*"
end
ENV["FERRUM_LOG"] ||= ENV["CUPRITE_LOG"] if ENV["CUPRITE_LOG"]

require "ferrum"
require "capybara"
require "capybara/cuprite/driver"
require "capybara/cuprite/browser"
require "capybara/cuprite/page"
require "capybara/cuprite/options"
require "capybara/cuprite/context"
require "capybara/cuprite/devices"
require "capybara/cuprite/node"
require "capybara/cuprite/errors"

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(app)
end

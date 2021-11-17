# frozen_string_literal: true

require_relative "lib/capybara/cuprite/version"

Gem::Specification.new do |s|
  s.name          = "cuprite"
  s.version       = Capybara::Cuprite::VERSION
  s.authors       = ["Dmitry Vorotilin"]
  s.email         = ["d.vorotilin@gmail.com"]
  s.homepage      = "https://github.com/rubycdp/cuprite"
  s.summary       = "Headless Chrome driver for Capybara"
  s.description   = "Cuprite is a driver for Capybara that allows you to " \
                    "run your tests on a headless Chrome browser"
  s.license       = "MIT"
  s.require_paths = ["lib"]
  s.files         = Dir["{lib}/**/*"] + %w[LICENSE README.md]
  s.metadata = {
    "homepage_uri" => "https://cuprite.rubycdp.com/",
    "bug_tracker_uri" => "https://github.com/rubycdp/cuprite/issues",
    "documentation_uri" => "https://github.com/rubycdp/cuprite/blob/master/README.md",
    "source_code_uri" => "https://github.com/rubycdp/cuprite",
    "rubygems_mfa_required" => "true"
  }

  s.required_ruby_version = ">= 2.6.0"

  s.add_runtime_dependency "capybara", "~> 3.0"
  s.add_runtime_dependency "ferrum",   "~> 0.11.0"

  s.add_development_dependency "byebug",     "~> 11.1"
  s.add_development_dependency "chunky_png", "~> 1.4"
  s.add_development_dependency "image_size", "~> 3.0"
  s.add_development_dependency "launchy",    "~> 2.5"
  s.add_development_dependency "pdf-reader", "~> 2.5"
  s.add_development_dependency "puma",       "~> 4.3"
  s.add_development_dependency "rake",       "~> 13.0"
  s.add_development_dependency "rspec",      "~> 3.10"
  s.add_development_dependency "sinatra",    "~> 2.1"
end

# frozen_string_literal: true

require "bundler/setup"
require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new("test") do |t|
  t.rspec_opts = "--format=documentation" if ENV["CI"]
end

desc "Validate RBS signatures in sig/"
task :rbs do
  sh "bundle exec rbs collection install"
  sh "bundle exec rbs -I sig validate"
end

task default: :test

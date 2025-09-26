# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

desc "Run security audit"
task :audit do
  sh "bundle audit --update"
  sh "bundle audit"
end

desc "Run all tests and security audit"
task :ci => [:spec, :audit]

task :default => :spec

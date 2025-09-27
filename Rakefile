# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

# Define RSpec task
RSpec::Core::RakeTask.new(:spec)

# Default task
task default: :spec

# Custom tasks for gem management
namespace :gem do
  desc "Build the gem"
  task :build do
    sh "gem build lipdub.gemspec"
  end

  desc "Install the gem locally"
  task install: :build do
    version = File.read("lib/lipdub/version.rb").match(/VERSION = "(.+)"/)[1]
    sh "gem install ./lipdub-#{version}.gem"
  end

  desc "Uninstall the gem"
  task :uninstall do
    version = File.read("lib/lipdub/version.rb").match(/VERSION = "(.+)"/)[1]
    sh "gem uninstall lipdub -v #{version}"
  end

  desc "Clean up built gems"
  task :clean do
    sh "rm -f *.gem"
  end

  desc "Push gem to RubyGems"
  task push: :build do
    version = File.read("lib/lipdub/version.rb").match(/VERSION = "(.+)"/)[1]
    sh "gem push lipdub-#{version}.gem"
  end
end

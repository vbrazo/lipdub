# frozen_string_literal: true

require_relative "lib/lipdub/version"

Gem::Specification.new do |spec|
  spec.name = "lipdub"
  spec.version = Lipdub::VERSION
  spec.authors = ["Upriser"]
  spec.email = ["support@upriser.com"]

  spec.summary = "Ruby client library for Lipdub.ai API"
  spec.description = "A comprehensive Ruby client for interacting with the Lipdub.ai API, providing video and audio upload capabilities, AI-powered lip-dubbing generation, and processing status monitoring."
  spec.homepage = "https://github.com/upriser/lipdub-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/upriser/lipdub-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/upriser/lipdub-ruby/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z 2>/dev/null`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "faraday-multipart", "~> 1.0"

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock", "~> 3.0"
  spec.add_development_dependency "vcr", "~> 6.0"
  spec.add_development_dependency "rubocop", "~> 1.0"
  spec.add_development_dependency "yard", "~> 0.9"
  spec.add_development_dependency "bundler-audit", "~> 0.9"
end

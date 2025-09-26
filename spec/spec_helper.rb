# frozen_string_literal: true

require "bundler/setup"
require "lipdub"
require "webmock/rspec"
require "vcr"

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Fix for RSpec::Support::Differ issue with WebMock
require 'rspec/support'
require 'rspec/support/differ'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on Module and main
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Clean up configuration before each test
  config.before(:each) do
    Lipdub.configuration = Lipdub::Configuration.new
  end
end

# WebMock configuration
WebMock.disable_net_connect!(allow_localhost: true)

# VCR configuration - disabled for pure WebMock testing
VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.default_cassette_options = {
    record: :once,
    match_requests_on: [:method, :uri, :body]
  }
  
  # Allow connections when no cassette is in use (for WebMock testing)
  config.allow_http_connections_when_no_cassette = true
  
  # Filter sensitive data
  config.filter_sensitive_data('<API_KEY>') { |interaction| 
    auth_header = interaction.request.headers['Authorization']&.first
    auth_header&.gsub('Bearer ', '') if auth_header&.start_with?('Bearer ')
  }
end

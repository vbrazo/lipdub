# frozen_string_literal: true

module WebMockHelpers
  def stub_json_request(method, url, response_body:, status: 200, request_body: nil, headers: {})
    stub = stub_request(method, url)
    
    # Add default headers
    default_headers = { 'Authorization' => "Bearer #{api_key}" }
    stub = stub.with(headers: default_headers.merge(headers))
    
    # Add request body if provided
    stub = stub.with(body: request_body.to_json) if request_body
    
    # Return JSON response
    stub.to_return(
      status: status,
      body: response_body.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
  end

  def stub_empty_json_request(method, url, status: 200, request_body: nil, headers: {})
    stub = stub_request(method, url)
    
    # Add default headers
    default_headers = { 'Authorization' => "Bearer #{api_key}" }
    stub = stub.with(headers: default_headers.merge(headers))
    
    # Add request body if provided
    stub = stub.with(body: request_body.to_json) if request_body
    
    # Return empty JSON response
    stub.to_return(
      status: status,
      body: "{}",
      headers: { 'Content-Type' => 'application/json' }
    )
  end
end

RSpec.configure do |config|
  config.include WebMockHelpers
end

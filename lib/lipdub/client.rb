# frozen_string_literal: true

module Lipdub
  class Client
    attr_reader :configuration

    def initialize(configuration = nil)
      @configuration = configuration || Lipdub.configuration
      validate_configuration!
    end

    def videos
      @videos ||= Resources::Videos.new(self)
    end

    def audios
      @audios ||= Resources::Audios.new(self)
    end

    def shots
      @shots ||= Resources::Shots.new(self)
    end

    def projects
      @projects ||= Resources::Projects.new(self)
    end

    def get(path, params = {})
      request(:get, path, params: params)
    end

    def post(path, body = {}, headers = {})
      request(:post, path, body: body, headers: headers)
    end

    def put(path, body = {}, headers = {})
      request(:put, path, body: body, headers: headers)
    end

    def put_file(url, file_content, content_type)
      connection = Faraday.new do |conn|
        conn.request :multipart
        conn.adapter Faraday.default_adapter
      end

      response = connection.put(url) do |req|
        req.headers['Content-Type'] = content_type
        req.body = file_content
      end

      case response.status
      when 200..299
        {}  # Return empty hash for successful file uploads
      else
        handle_response(response)
      end
    end

    private

    def request(method, path, params: {}, body: {}, headers: {})
      response = connection.public_send(method, path) do |req|
        req.params.merge!(params) if params.any?
        req.headers.merge!(headers) if headers.any?
        req.body = body.to_json if body.any? && !body.is_a?(String)
      end

      handle_response(response)
    rescue Faraday::TimeoutError => e
      raise TimeoutError, "Request timed out: #{e.message}"
    rescue Faraday::ConnectionFailed => e
      # WebMock timeout simulation raises ConnectionFailed with "execution expired"
      if e.message.include?("execution expired")
        raise TimeoutError, "Request timed out: #{e.message}"
      else
        raise ConnectionError, "Connection failed: #{e.message}"
      end
    end

    def connection
      @connection ||= Faraday.new(url: configuration.base_url) do |conn|
        conn.request :json
        conn.response :json, content_type: /\bjson$/
        conn.response :json # Add fallback JSON parsing
        conn.headers['Authorization'] = "Bearer #{configuration.api_key}"
        conn.headers['User-Agent'] = "lipdub-ruby/#{VERSION}"
        conn.options.timeout = configuration.timeout
        conn.options.open_timeout = configuration.open_timeout
        conn.adapter Faraday.default_adapter
      end
    end

    def handle_response(response)
      case response.status
      when 200..299
        response.body || {}
      when 401
        raise AuthenticationError.new("Authentication failed", 
                                     status_code: response.status, 
                                     response_body: response.body)
      when 422
        raise ValidationError.new("Validation error: #{extract_error_message(response)}", 
                                 status_code: response.status, 
                                 response_body: response.body)
      when 404
        raise NotFoundError.new("Resource not found", 
                               status_code: response.status, 
                               response_body: response.body)
      when 429
        raise RateLimitError.new("Rate limit exceeded", 
                                status_code: response.status, 
                                response_body: response.body)
      when 500..599
        raise ServerError.new("Server error", 
                             status_code: response.status, 
                             response_body: response.body)
      else
        raise APIError.new("Unexpected response: #{response.status}", 
                          status_code: response.status, 
                          response_body: response.body)
      end
    end

    def extract_error_message(response)
      return response.reason_phrase unless response.body.is_a?(Hash)
      
      message = response.body.dig("error", "message") || 
                response.body["message"] || 
                response.body["error"] || 
                response.reason_phrase
      
      message.to_s.empty? ? response.reason_phrase : message
    end

    def validate_configuration!
      raise ConfigurationError, "API key is required" unless configuration.valid?
    end
  end
end

# frozen_string_literal: true

RSpec.describe Lipdub::Client do
  let(:api_key) { "test_api_key" }
  let(:configuration) do
    config = Lipdub::Configuration.new
    config.api_key = api_key
    config
  end
  let(:client) { described_class.new(configuration) }

  describe "#initialize" do
    context "with valid configuration" do
      it "creates a client" do
        expect(client).to be_a(described_class)
        expect(client.configuration).to eq(configuration)
      end
    end

    context "with invalid configuration" do
      let(:invalid_config) { Lipdub::Configuration.new }

      it "raises ConfigurationError" do
        expect { described_class.new(invalid_config) }.to raise_error(Lipdub::ConfigurationError)
      end
    end

    context "without configuration" do
      before do
        Lipdub.configure { |config| config.api_key = api_key }
      end

      it "uses global configuration" do
        client = described_class.new
        expect(client.configuration).to eq(Lipdub.configuration)
      end
    end
  end

  describe "resource methods" do
    it "returns videos resource" do
      expect(client.videos).to be_a(Lipdub::Resources::Videos)
    end

    it "returns audios resource" do
      expect(client.audios).to be_a(Lipdub::Resources::Audios)
    end

    it "returns shots resource" do
      expect(client.shots).to be_a(Lipdub::Resources::Shots)
    end

    it "returns projects resource" do
      expect(client.projects).to be_a(Lipdub::Resources::Projects)
    end

    it "memoizes resource instances" do
      videos1 = client.videos
      videos2 = client.videos
      expect(videos1).to be(videos2)
      
      projects1 = client.projects
      projects2 = client.projects
      expect(projects1).to be(projects2)
    end
  end

  describe "HTTP methods" do
    let(:base_url) { "https://api.lipdub.ai" }

    before do
      stub_request(:get, "#{base_url}/test")
        .with(headers: { 'Authorization' => "Bearer #{api_key}" })
        .to_return(status: 200, body: '{"success": true}', headers: { 'Content-Type' => 'application/json' })
    end

    describe "#get" do
      it "makes GET request with proper headers" do
        response = client.get("/test")
        expect(response).to eq({ "success" => true })
      end

      it "includes query parameters" do
        stub_request(:get, "#{base_url}/test?param=value")
          .with(headers: { 'Authorization' => "Bearer #{api_key}" })
          .to_return(status: 200, body: '{"success": true}', headers: { 'Content-Type' => 'application/json' })

        client.get("/test", { param: "value" })
      end
    end

    describe "#post" do
      before do
        stub_request(:post, "#{base_url}/test")
          .with(
            headers: { 'Authorization' => "Bearer #{api_key}", 'Content-Type' => 'application/json' },
            body: '{"data":"value"}'
          )
          .to_return(status: 201, body: '{"created": true}', headers: { 'Content-Type' => 'application/json' })
      end

      it "makes POST request with JSON body" do
        response = client.post("/test", { data: "value" })
        expect(response).to eq({ "created" => true })
      end
    end

    describe "#put_file" do
      let(:file_content) { "test file content" }
      let(:content_type) { "video/mp4" }
      let(:upload_url) { "https://storage.lipdub.ai/upload/test" }

      before do
        stub_request(:put, upload_url)
          .with(
            headers: { 'Content-Type' => content_type },
            body: file_content
          )
          .to_return(status: 200, body: "")
      end

      it "uploads file content to external URL" do
        response = client.put_file(upload_url, file_content, content_type)
        expect(response).to eq({})
      end
    end
  end

  describe "error handling" do
    let(:base_url) { "https://api.lipdub.ai" }

    context "when API returns 401" do
      before do
        stub_request(:get, "#{base_url}/test")
          .to_return(status: 401, body: '{"error": "Unauthorized"}')
      end

      it "raises AuthenticationError" do
        expect { client.get("/test") }.to raise_error(Lipdub::AuthenticationError)
      end
    end

    context "when API returns 422" do
      before do
        stub_request(:get, "#{base_url}/test")
          .to_return(status: 422, body: '{"error": {"message": "Validation failed"}}', headers: { 'Content-Type' => 'application/json' })
      end

      it "raises ValidationError" do
        expect { client.get("/test") }.to raise_error(Lipdub::ValidationError, /Validation failed/)
      end
    end

    context "when API returns 404" do
      before do
        stub_request(:get, "#{base_url}/test")
          .to_return(status: 404, body: '{"error": "Not found"}', headers: { 'Content-Type' => 'application/json' })
      end

      it "raises NotFoundError" do
        expect { client.get("/test") }.to raise_error(Lipdub::NotFoundError)
      end
    end

    context "when API returns 429" do
      before do
        stub_request(:get, "#{base_url}/test")
          .to_return(status: 429, body: '{"error": "Rate limit exceeded"}', headers: { 'Content-Type' => 'application/json' })
      end

      it "raises RateLimitError" do
        expect { client.get("/test") }.to raise_error(Lipdub::RateLimitError)
      end
    end

    context "when API returns 500" do
      before do
        stub_request(:get, "#{base_url}/test")
          .to_return(status: 500, body: '{"error": "Internal server error"}', headers: { 'Content-Type' => 'application/json' })
      end

      it "raises ServerError" do
        expect { client.get("/test") }.to raise_error(Lipdub::ServerError)
      end
    end

    context "when connection times out" do
      before do
        stub_request(:get, "#{base_url}/test").to_timeout
      end

      it "raises TimeoutError" do
        expect { client.get("/test") }.to raise_error(Lipdub::TimeoutError)
      end
    end

    context "when connection fails" do
      before do
        stub_request(:get, "#{base_url}/test").to_raise(Faraday::ConnectionFailed)
      end

      it "raises ConnectionError" do
        expect { client.get("/test") }.to raise_error(Lipdub::ConnectionError)
      end
    end
  end
end

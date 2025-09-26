# frozen_string_literal: true

RSpec.describe Lipdub::Resources::Projects do
  let(:api_key) { "test_api_key" }
  let(:configuration) do
    config = Lipdub::Configuration.new
    config.api_key = api_key
    config
  end
  let(:client) { Lipdub::Client.new(configuration) }
  let(:projects) { client.projects }
  let(:base_url) { "https://api.lipdub.ai" }

  describe "#list" do
    let(:expected_response) do
      {
        "data" => [
          {
            "project_id" => 123,
            "projects_tenant_id" => 1,
            "projects_user_id" => 47,
            "project_name" => "My Sample Project",
            "user_email" => "user@example.com",
            "created_at" => "2024-01-15T10:30:00Z",
            "updated_at" => nil,
            "source_language" => {
              "language_id" => 1,
              "name" => "English",
              "supported" => true
            },
            "project_identity_type" => "single_identity",
            "language_project_links" => []
          }
        ],
        "count" => 1
      }
    end

    before do
      stub_request(:get, "#{base_url}/v1/projects?page=1&per_page=20")
        .to_return(status: 200, body: expected_response.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it "lists projects with default parameters" do
      response = projects.list
      expect(response).to eq(expected_response)
    end

    context "with custom parameters" do
      before do
        stub_request(:get, "#{base_url}/v1/projects?page=3&per_page=50")
          .to_return(status: 200, body: expected_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it "lists projects with custom page and per_page" do
        response = projects.list(page: 3, per_page: 50)
        expect(response).to eq(expected_response)
      end
    end

    context "with invalid parameters" do
      it "raises ValidationError for invalid page" do
        expect { projects.list(page: 0) }.to raise_error(Lipdub::ValidationError, /Page must be >= 1/)
      end

      it "raises ValidationError for invalid per_page" do
        expect { projects.list(per_page: 101) }.to raise_error(Lipdub::ValidationError, /Per page must be between 1 and 100/)
      end

      it "raises ValidationError for negative per_page" do
        expect { projects.list(per_page: 0) }.to raise_error(Lipdub::ValidationError, /Per page must be between 1 and 100/)
      end
    end
  end
end

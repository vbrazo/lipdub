# frozen_string_literal: true

RSpec.describe Lipdub::Resources::Videos do
  let(:api_key) { "test_api_key" }
  let(:configuration) do
    config = Lipdub::Configuration.new
    config.api_key = api_key
    config
  end
  let(:client) { Lipdub::Client.new(configuration) }
  let(:videos) { client.videos }
  let(:base_url) { "https://api.lipdub.ai" }

  describe "#upload" do
    let(:upload_params) do
      {
        size_bytes: 52428800,
        file_name: "test_video.mp4",
        content_type: "video/mp4"
      }
    end

    let(:expected_response) do
      {
        "data" => {
          "video_id" => "video_123",
          "upload_url" => "https://storage.lipdub.ai/upload/video_123?token=xyz",
          "success_url" => "https://api.lipdub.ai/v1/video/success/video_123",
          "failure_url" => "https://api.lipdub.ai/v1/video/failure/video_123"
        }
      }
    end

    before do
      stub_request(:post, "#{base_url}/v1/video")
        .with(
          headers: { 'Authorization' => "Bearer #{api_key}" },
          body: upload_params.to_json
        )
        .to_return(status: 201, body: expected_response.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it "initiates video upload" do
      response = videos.upload(**upload_params)
      expect(response).to eq(expected_response)
    end

    context "with video_source_url" do
      let(:upload_params_with_url) do
        upload_params.merge(video_source_url: "https://example.com/video.mp4")
      end

      before do
        stub_request(:post, "#{base_url}/v1/video")
          .with(
            headers: { 'Authorization' => "Bearer #{api_key}" },
            body: upload_params_with_url.to_json
          )
          .to_return(status: 201, body: expected_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it "includes video_source_url in request" do
        response = videos.upload(**upload_params_with_url)
        expect(response).to eq(expected_response)
      end
    end
  end

  describe "#upload_file" do
    let(:upload_url) { "https://storage.lipdub.ai/upload/video_123?token=xyz" }
    let(:file_content) { "fake video content" }
    let(:content_type) { "video/mp4" }

    before do
      stub_request(:put, upload_url)
        .with(
          headers: { 'Content-Type' => content_type },
          body: file_content
        )
        .to_return(status: 200, body: "")
    end

    it "uploads file to provided URL" do
      response = videos.upload_file(upload_url, file_content, content_type)
      expect(response).to eq({})
    end
  end

  describe "#upload_complete" do
    let(:file_path) { "/tmp/test_video.mp4" }
    let(:file_content) { "fake video content" }
    let(:upload_url) { "https://storage.lipdub.ai/upload/video_123?token=xyz" }
    let(:video_id) { "video_123" }

    let(:upload_response) do
      {
        "data" => {
          "video_id" => video_id,
          "upload_url" => upload_url,
          "success_url" => "https://api.lipdub.ai/v1/video/success/#{video_id}",
          "failure_url" => "https://api.lipdub.ai/v1/video/failure/#{video_id}"
        }
      }
    end

    let(:success_response) do
      {
        "data" => {
          "shot_id" => 123,
          "asset_type" => "dubbing-video"
        }
      }
    end

    before do
      # Mock file operations
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:basename).and_call_original
      allow(File).to receive(:size).and_call_original
      
      allow(File).to receive(:exist?).with(file_path).and_return(true)
      allow(File).to receive(:read).with(file_path).and_return(file_content)
      allow(File).to receive(:basename).with(file_path).and_return("test_video.mp4")
      allow(File).to receive(:size).with(file_path).and_return(file_content.length)

      # Mock API calls
      stub_request(:post, "#{base_url}/v1/video")
          .to_return(status: 201, body: upload_response.to_json, headers: { 'Content-Type' => 'application/json' })

      stub_request(:put, upload_url)
        .to_return(status: 200, body: "")

      stub_request(:post, "#{base_url}/v1/video/success/#{video_id}")
        .to_return(status: 200, body: success_response.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it "completes the entire upload workflow" do
      response = videos.upload_complete(file_path)
      expect(response).to eq(success_response)
    end

    context "when file does not exist" do
      before do
        allow(File).to receive(:exist?).with(file_path).and_return(false)
      end

      it "raises ArgumentError" do
        expect { videos.upload_complete(file_path) }.to raise_error(ArgumentError, /File does not exist/)
      end
    end

    context "when upload fails" do
      before do
        stub_request(:put, upload_url).to_return(status: 500)
        stub_request(:post, "#{base_url}/v1/video/failure/#{video_id}")
          .to_return(status: 200, body: "{}", headers: { 'Content-Type' => 'application/json' })
      end

      it "calls failure endpoint and re-raises error" do
        expect { videos.upload_complete(file_path) }.to raise_error(Lipdub::ServerError)
        expect(WebMock).to have_requested(:post, "#{base_url}/v1/video/failure/#{video_id}")
      end
    end
  end

  describe "#success" do
    let(:video_id) { "video_123" }
    let(:expected_response) do
      {
        "data" => {
          "shot_id" => 123,
          "asset_type" => "dubbing-video"
        }
      }
    end

    before do
      stub_request(:post, "#{base_url}/v1/video/success/#{video_id}")
        .to_return(status: 200, body: expected_response.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it "marks video upload as successful" do
      response = videos.success(video_id)
      expect(response).to eq(expected_response)
    end
  end

  describe "#failure" do
    let(:video_id) { "video_123" }

    before do
      stub_request(:post, "#{base_url}/v1/video/failure/#{video_id}")
        .to_return(status: 200, body: "{}", headers: { 'Content-Type' => 'application/json' })
    end

    it "marks video upload as failed" do
      response = videos.failure(video_id)
      expect(response).to eq({})
    end
  end

  describe "#status" do
    let(:video_id) { "video_123" }
    let(:expected_response) do
      {
        "data" => {
          "status" => "processing",
          "progress" => 50
        }
      }
    end

    before do
      stub_request(:get, "#{base_url}/v1/video/status/#{video_id}")
        .to_return(status: 200, body: expected_response.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it "gets video processing status" do
      response = videos.status(video_id)
      expect(response).to eq(expected_response)
    end
  end

  describe "#detect_content_type" do
    it "detects MP4 content type" do
      expect(videos.send(:detect_content_type, "video.mp4")).to eq("video/mp4")
    end

    it "detects MOV content type" do
      expect(videos.send(:detect_content_type, "video.mov")).to eq("video/quicktime")
    end

    it "detects AVI content type" do
      expect(videos.send(:detect_content_type, "video.avi")).to eq("video/x-msvideo")
    end

    it "detects WebM content type" do
      expect(videos.send(:detect_content_type, "video.webm")).to eq("video/webm")
    end

    it "detects MKV content type" do
      expect(videos.send(:detect_content_type, "video.mkv")).to eq("video/x-matroska")
    end

    it "defaults to MP4 for unknown extensions" do
      expect(videos.send(:detect_content_type, "video.unknown")).to eq("video/mp4")
    end
  end
end

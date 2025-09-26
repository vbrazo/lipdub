# frozen_string_literal: true

RSpec.describe Lipdub::Resources::Audios do
  let(:api_key) { "test_api_key" }
  let(:configuration) do
    config = Lipdub::Configuration.new
    config.api_key = api_key
    config
  end
  let(:client) { Lipdub::Client.new(configuration) }
  let(:audios) { client.audios }
  let(:base_url) { "https://api.lipdub.ai" }

  describe "#upload" do
    let(:upload_params) do
      {
        size_bytes: 5242880,
        file_name: "voiceover.mp3",
        content_type: "audio/mpeg"
      }
    end

    let(:expected_response) do
      {
        "data" => {
          "audio_id" => "audio_123",
          "upload_url" => "https://storage.lipdub.ai/upload/audio_123?token=xyz",
          "success_url" => "https://api.lipdub.ai/v1/audio/success/audio_123",
          "failure_url" => "https://api.lipdub.ai/v1/audio/failure/audio_123"
        }
      }
    end

    before do
      stub_request(:post, "#{base_url}/v1/audio")
        .with(
          headers: { 'Authorization' => "Bearer #{api_key}" },
          body: upload_params.to_json
        )
        .to_return(
          status: 201, 
          body: expected_response.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it "initiates audio upload" do
      response = audios.upload(**upload_params)
      expect(response).to eq(expected_response)
    end

    context "with audio_source_url" do
      let(:upload_params_with_url) do
        upload_params.merge(audio_source_url: "https://example.com/audio.mp3")
      end

      before do
        stub_request(:post, "#{base_url}/v1/audio")
          .with(
            headers: { 'Authorization' => "Bearer #{api_key}" },
            body: upload_params_with_url.to_json
          )
          .to_return(
            status: 201, 
            body: expected_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it "includes audio_source_url in request" do
        response = audios.upload(**upload_params_with_url)
        expect(response).to eq(expected_response)
      end
    end

    context "with invalid size_bytes" do
      it "raises ValidationError for size too small" do
        expect do
          audios.upload(size_bytes: 0, file_name: "test.mp3", content_type: "audio/mpeg")
        end.to raise_error(Lipdub::ValidationError, /Audio file size must be between/)
      end

      it "raises ValidationError for size too large" do
        expect do
          audios.upload(size_bytes: 104857601, file_name: "test.mp3", content_type: "audio/mpeg")
        end.to raise_error(Lipdub::ValidationError, /Audio file size must be between/)
      end
    end

    context "with invalid content_type" do
      it "raises ValidationError" do
        expect do
          audios.upload(size_bytes: 1000, file_name: "test.mp3", content_type: "audio/invalid")
        end.to raise_error(Lipdub::ValidationError, /Content type must be one of/)
      end
    end
  end

  describe "#upload_file" do
    let(:upload_url) { "https://storage.lipdub.ai/upload/audio_123?token=xyz" }
    let(:file_content) { "fake audio content" }
    let(:content_type) { "audio/mpeg" }

    before do
      stub_request(:put, upload_url)
        .with(
          headers: { 'Content-Type' => content_type },
          body: file_content
        )
        .to_return(status: 200, body: "")
    end

    it "uploads file to provided URL" do
      response = audios.upload_file(upload_url, file_content, content_type)
      expect(response).to eq({})
    end
  end

  describe "#upload_complete" do
    let(:file_path) { "/tmp/test_audio.mp3" }
    let(:file_content) { "fake audio content" }
    let(:upload_url) { "https://storage.lipdub.ai/upload/audio_123?token=xyz" }
    let(:audio_id) { "audio_123" }

    let(:upload_response) do
      {
        "data" => {
          "audio_id" => audio_id,
          "upload_url" => upload_url,
          "success_url" => "https://api.lipdub.ai/v1/audio/success/#{audio_id}",
          "failure_url" => "https://api.lipdub.ai/v1/audio/failure/#{audio_id}"
        }
      }
    end

    let(:success_response) { {} }

    before do
      # Mock file operations
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:basename).and_call_original
      allow(File).to receive(:size).and_call_original
      
      allow(File).to receive(:exist?).with(file_path).and_return(true)
      allow(File).to receive(:read).with(file_path).and_return(file_content)
      allow(File).to receive(:basename).with(file_path).and_return("test_audio.mp3")
      allow(File).to receive(:size).with(file_path).and_return(file_content.length)

      # Mock API calls
      stub_request(:post, "#{base_url}/v1/audio")
          .to_return(status: 201, body: upload_response.to_json, headers: { 'Content-Type' => 'application/json' })

      stub_request(:put, upload_url)
        .to_return(status: 200, body: "")

      stub_request(:post, "#{base_url}/v1/audio/success/#{audio_id}")
        .to_return(status: 200, body: success_response.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it "completes the entire upload workflow" do
      response = audios.upload_complete(file_path)
      expect(response).to eq(success_response)
    end

    context "when file does not exist" do
      before do
        allow(File).to receive(:exist?).with(file_path).and_return(false)
      end

      it "raises ArgumentError" do
        expect { audios.upload_complete(file_path) }.to raise_error(ArgumentError, /File does not exist/)
      end
    end

    context "when upload fails" do
      before do
        stub_request(:put, upload_url).to_return(status: 500)
        stub_request(:post, "#{base_url}/v1/audio/failure/#{audio_id}")
          .to_return(status: 200, body: "{}", headers: { 'Content-Type' => 'application/json' })
      end

      it "calls failure endpoint and re-raises error" do
        expect { audios.upload_complete(file_path) }.to raise_error(Lipdub::ServerError)
        expect(WebMock).to have_requested(:post, "#{base_url}/v1/audio/failure/#{audio_id}")
      end
    end
  end

  describe "#success" do
    let(:audio_id) { "audio_123" }

    before do
      stub_request(:post, "#{base_url}/v1/audio/success/#{audio_id}")
        .to_return(status: 200, body: "{}", headers: { 'Content-Type' => 'application/json' })
    end

    it "marks audio upload as successful" do
      response = audios.success(audio_id)
      expect(response).to eq({})
    end
  end

  describe "#failure" do
    let(:audio_id) { "audio_123" }

    before do
      stub_request(:post, "#{base_url}/v1/audio/failure/#{audio_id}")
        .to_return(status: 200, body: "{}", headers: { 'Content-Type' => 'application/json' })
    end

    it "marks audio upload as failed" do
      response = audios.failure(audio_id)
      expect(response).to eq({})
    end
  end

  describe "#status" do
    let(:audio_id) { "audio_123" }
    let(:expected_response) do
      {
        "data" => {
          "status" => "processing",
          "progress" => 75
        }
      }
    end

    before do
      stub_request(:get, "#{base_url}/v1/audio/status/#{audio_id}")
        .to_return(status: 200, body: expected_response.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it "gets audio processing status" do
      response = audios.status(audio_id)
      expect(response).to eq(expected_response)
    end
  end

  describe "#list" do
    let(:expected_response) do
      {
        "data" => [
          { "audio_id" => "audio_1", "file_name" => "audio1.mp3" },
          { "audio_id" => "audio_2", "file_name" => "audio2.wav" }
        ],
        "pagination" => {
          "page" => 1,
          "page_size" => 10,
          "total" => 2
        }
      }
    end

    before do
      stub_request(:get, "#{base_url}/v1/audio?page=1&page_size=10")
        .to_return(status: 200, body: expected_response.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it "lists audio files with default parameters" do
      response = audios.list
      expect(response).to eq(expected_response)
    end

    context "with custom parameters" do
      before do
        stub_request(:get, "#{base_url}/v1/audio?page=2&page_size=20")
          .to_return(status: 200, body: expected_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it "lists audio files with custom page and page_size" do
        response = audios.list(page: 2, page_size: 20)
        expect(response).to eq(expected_response)
      end
    end
  end

  describe "#detect_content_type" do
    it "detects MP3 content type" do
      expect(audios.send(:detect_content_type, "audio.mp3")).to eq("audio/mpeg")
    end

    it "detects WAV content type" do
      expect(audios.send(:detect_content_type, "audio.wav")).to eq("audio/wav")
    end

    it "detects MP4 content type" do
      expect(audios.send(:detect_content_type, "audio.mp4")).to eq("audio/mp4")
    end

    it "detects M4A content type" do
      expect(audios.send(:detect_content_type, "audio.m4a")).to eq("audio/mp4")
    end

    it "defaults to MP3 for unknown extensions" do
      expect(audios.send(:detect_content_type, "audio.unknown")).to eq("audio/mpeg")
    end
  end
end

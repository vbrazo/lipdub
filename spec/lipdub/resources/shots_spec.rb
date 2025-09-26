# frozen_string_literal: true

RSpec.describe Lipdub::Resources::Shots do
  let(:api_key) { "test_api_key" }
  let(:configuration) do
    config = Lipdub::Configuration.new
    config.api_key = api_key
    config
  end
  let(:client) { Lipdub::Client.new(configuration) }
  let(:shots) { client.shots }
  let(:base_url) { "https://api.lipdub.ai" }

  describe "#list" do
    let(:expected_response) do
      {
        "data" => [
          {
            "shot_id" => 99,
            "shot_label" => "api-full-test-new.mp4",
            "shot_project_id" => 37,
            "shot_scene_id" => 37,
            "shot_project_name" => "Lee Studios",
            "shot_scene_name" => "Under the tent"
          }
        ],
        "count" => 1
      }
    end

    before do
      stub_request(:get, "#{base_url}/v1/shots?page=1&per_page=20")
        .to_return(status: 200, body: expected_response.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it "lists shots with default parameters" do
      response = shots.list
      expect(response).to eq(expected_response)
    end

    context "with custom parameters" do
      before do
        stub_request(:get, "#{base_url}/v1/shots?page=2&per_page=50")
          .to_return(status: 200, body: expected_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it "lists shots with custom page and per_page" do
        response = shots.list(page: 2, per_page: 50)
        expect(response).to eq(expected_response)
      end
    end

    context "with invalid parameters" do
      it "raises ValidationError for invalid page" do
        expect { shots.list(page: 0) }.to raise_error(Lipdub::ValidationError, /Page must be >= 1/)
      end

      it "raises ValidationError for invalid per_page" do
        expect { shots.list(per_page: 101) }.to raise_error(Lipdub::ValidationError, /Per page must be between 1 and 100/)
      end
    end
  end

  describe "#status" do
    let(:shot_id) { 123 }
    let(:expected_response) do
      {
        "data" => {
          "shot_id" => shot_id,
          "status" => "processing",
          "video_processing" => "completed",
          "ai_training" => "in_progress",
          "progress" => 60
        }
      }
    end

    before do
      stub_request(:get, "#{base_url}/v1/shots/#{shot_id}/status")
        .to_return(status: 200, body: expected_response.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it "gets shot processing status" do
      response = shots.status(shot_id)
      expect(response).to eq(expected_response)
    end
  end

  describe "#generate" do
    let(:shot_id) { 123 }
    let(:audio_id) { "audio_456" }
    let(:output_filename) { "dubbed_video.mp4" }
    
    let(:generate_params) do
      {
        shot_id: shot_id,
        audio_id: audio_id,
        output_filename: output_filename
      }
    end

    let(:expected_response) do
      {
        "generate_id" => 456
      }
    end

    before do
      stub_request(:post, "#{base_url}/v1/shots/#{shot_id}/generate")
        .with(
          headers: { 'Authorization' => "Bearer #{api_key}" },
          body: {
            audio_id: audio_id,
            output_filename: output_filename
          }.to_json
        )
        .to_return(status: 201, body: expected_response.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it "generates lip-dubbed video" do
      response = shots.generate(**generate_params)
      expect(response).to eq(expected_response)
    end

    context "with all optional parameters" do
      let(:generate_params_with_options) do
        generate_params.merge(
          language: "en-US",
          start_frame: 10,
          loop_video: true,
          full_resolution: false,
          callback_url: "https://example.com/webhook",
          timecode_ranges: [[0, 100], [200, 300]]
        )
      end

      before do
        stub_request(:post, "#{base_url}/v1/shots/#{shot_id}/generate")
          .with(
            headers: { 'Authorization' => "Bearer #{api_key}" },
            body: {
              audio_id: audio_id,
              output_filename: output_filename,
              language: "en-US",
              start_frame: 10,
              loop_video: true,
              full_resolution: false,
              callback_url: "https://example.com/webhook",
              timecode_ranges: [[0, 100], [200, 300]]
            }.to_json
          )
          .to_return(status: 201, body: expected_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it "includes all optional parameters in request" do
        response = shots.generate(**generate_params_with_options)
        expect(response).to eq(expected_response)
      end
    end
  end

  describe "#generation_status" do
    let(:shot_id) { 123 }
    let(:generate_id) { "gen_789" }
    let(:expected_response) do
      {
        "data" => {
          "generate_id" => generate_id,
          "status" => "completed",
          "progress" => 100
        }
      }
    end

    before do
      stub_request(:get, "#{base_url}/v1/shots/#{shot_id}/generate/#{generate_id}")
        .to_return(status: 200, body: expected_response.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it "gets generation status" do
      response = shots.generation_status(shot_id, generate_id)
      expect(response).to eq(expected_response)
    end
  end

  describe "#download" do
    let(:shot_id) { 123 }
    let(:generate_id) { "gen_789" }
    let(:expected_response) do
      {
        "data" => {
          "download_url" => "https://storage.lipdub.ai/download/gen_789?token=xyz"
        }
      }
    end

    before do
      stub_request(:get, "#{base_url}/v1/shots/#{shot_id}/generate/#{generate_id}/download")
        .to_return(status: 200, body: expected_response.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it "gets download URL for generated video" do
      response = shots.download(shot_id, generate_id)
      expect(response).to eq(expected_response)
    end
  end

  describe "#download_file" do
    let(:shot_id) { 123 }
    let(:generate_id) { "gen_789" }
    let(:file_path) { "/tmp/output_video.mp4" }
    let(:download_url) { "https://storage.lipdub.ai/download/gen_789?token=xyz" }
    let(:file_content) { "fake video file content" }

    before do
      # Mock download endpoint
      stub_request(:get, "#{base_url}/v1/shots/#{shot_id}/generate/#{generate_id}/download")
        .to_return(status: 200, body: {
          "data" => { "download_url" => download_url }
        }.to_json)

      # Mock file download
      stub_request(:get, download_url)
        .to_return(status: 200, body: file_content)

      # Mock file system operations
      allow(FileUtils).to receive(:mkdir_p)
      allow(File).to receive(:open).with(file_path, 'wb').and_yield(double(write: nil))
      allow(File).to receive(:dirname).with(file_path).and_return("/tmp")
    end

    it "downloads file to local path" do
      result = shots.download_file(shot_id, generate_id, file_path)
      expect(result).to eq(file_path)
      expect(FileUtils).to have_received(:mkdir_p).with("/tmp")
    end

    context "when download URL is missing" do
      before do
        stub_request(:get, "#{base_url}/v1/shots/#{shot_id}/generate/#{generate_id}/download")
          .to_return(status: 200, body: { "data" => {} }.to_json)
      end

      it "raises APIError" do
        expect do
          shots.download_file(shot_id, generate_id, file_path)
        end.to raise_error(Lipdub::APIError, /Download URL not found/)
      end
    end

    context "when file download fails" do
      before do
        stub_request(:get, download_url).to_return(status: 404)
      end

      it "raises APIError" do
        expect do
          shots.download_file(shot_id, generate_id, file_path)
        end.to raise_error(Lipdub::APIError, /Failed to download file/)
      end
    end
  end

  describe "#generate_and_wait" do
    let(:shot_id) { 123 }
    let(:audio_id) { "audio_456" }
    let(:output_filename) { "dubbed_video.mp4" }
    let(:generate_id) { "gen_789" }

    let(:generate_response) do
      {
        "data" => {
          "generate_id" => generate_id,
          "status" => "processing"
        }
      }
    end

    let(:processing_response) do
      {
        "data" => {
          "generate_id" => generate_id,
          "status" => "processing",
          "progress" => 50
        }
      }
    end

    let(:completed_response) do
      {
        "data" => {
          "generate_id" => generate_id,
          "status" => "completed",
          "progress" => 100
        }
      }
    end

    before do
      # Mock generation start
      stub_request(:post, "#{base_url}/v1/shots/#{shot_id}/generate")
        .to_return(status: 201, body: generate_response.to_json)

      # Mock status checks
      stub_request(:get, "#{base_url}/v1/shots/#{shot_id}/generate/#{generate_id}")
        .to_return(
          { status: 200, body: processing_response.to_json },
          { status: 200, body: completed_response.to_json }
        )

      # Mock sleep to speed up tests
      allow(shots).to receive(:sleep)
    end

    it "generates and waits for completion" do
      response = shots.generate_and_wait(
        shot_id: shot_id,
        audio_id: audio_id,
        output_filename: output_filename,
        polling_interval: 1,
        max_wait_time: 10
      )

      expect(response).to eq(completed_response)
      expect(shots).to have_received(:sleep).with(1)
    end

    context "when generation fails" do
      let(:failed_response) do
        {
          "data" => {
            "generate_id" => generate_id,
            "status" => "failed",
            "error" => "Processing error"
          }
        }
      end

      before do
        stub_request(:get, "#{base_url}/v1/shots/#{shot_id}/generate/#{generate_id}")
          .to_return(status: 200, body: failed_response.to_json)
      end

      it "raises APIError" do
        expect do
          shots.generate_and_wait(
            shot_id: shot_id,
            audio_id: audio_id,
            output_filename: output_filename,
            polling_interval: 1,
            max_wait_time: 10
          )
        end.to raise_error(Lipdub::APIError, /Generation failed/)
      end
    end

    context "when generation times out" do
      before do
        stub_request(:get, "#{base_url}/v1/shots/#{shot_id}/generate/#{generate_id}")
          .to_return(status: 200, body: processing_response.to_json).times(10)

        allow(Time).to receive(:now).and_return(Time.at(0), Time.at(15))
      end

      it "raises TimeoutError" do
        expect do
          shots.generate_and_wait(
            shot_id: shot_id,
            audio_id: audio_id,
            output_filename: output_filename,
            polling_interval: 1,
            max_wait_time: 10
          )
        end.to raise_error(Lipdub::TimeoutError, /did not complete within/)
      end
    end

    context "when generate_id is missing" do
      let(:invalid_generate_response) do
        { "data" => { "status" => "processing" } }
      end

      before do
        stub_request(:post, "#{base_url}/v1/shots/#{shot_id}/generate")
          .to_return(status: 201, body: invalid_generate_response.to_json)
      end

      it "raises APIError" do
        expect do
          shots.generate_and_wait(
            shot_id: shot_id,
            audio_id: audio_id,
            output_filename: output_filename
          )
        end.to raise_error(Lipdub::APIError, /Generate ID not found/)
      end
    end
  end

  describe "#actors" do
    let(:shot_id) { 123 }
    let(:expected_response) do
      {
        "data" => [
          { "actor_id" => 1, "name" => "Actor 1" },
          { "actor_id" => 2, "name" => "Actor 2" }
        ]
      }
    end

    before do
      stub_request(:get, "#{base_url}/v1/shots/#{shot_id}/actors")
        .to_return(status: 200, body: expected_response.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it "gets actors for a shot" do
      response = shots.actors(shot_id)
      expect(response).to eq(expected_response)
    end
  end

  describe "#translate" do
    let(:shot_id) { 123 }
    let(:translate_params) do
      {
        shot_id: shot_id,
        source_language: "English",
        target_language: "Spanish"
      }
    end

    let(:expected_response) do
      {
        "data" => {
          "translation_id" => "trans_456",
          "status" => "processing"
        }
      }
    end

    before do
      stub_request(:post, "#{base_url}/v1/shots/#{shot_id}/translate")
        .with(
          headers: { 'Authorization' => "Bearer #{api_key}" },
          body: {
            source_language: "English",
            target_language: "Spanish"
          }.to_json
        )
        .to_return(status: 201, body: expected_response.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it "translates a shot" do
      response = shots.translate(**translate_params)
      expect(response).to eq(expected_response)
    end

    context "with full_resolution parameter" do
      let(:translate_params_with_resolution) do
        translate_params.merge(full_resolution: false)
      end

      before do
        stub_request(:post, "#{base_url}/v1/shots/#{shot_id}/translate")
          .with(
            headers: { 'Authorization' => "Bearer #{api_key}" },
            body: {
              source_language: "English",
              target_language: "Spanish",
              full_resolution: false
            }.to_json
          )
          .to_return(status: 201, body: expected_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it "includes full_resolution parameter" do
        response = shots.translate(**translate_params_with_resolution)
        expect(response).to eq(expected_response)
      end
    end
  end

  describe "#generate_multi_actor" do
    let(:shot_id) { 123 }
    let(:multi_actor_params) do
      {
        shot_id: shot_id,
        actors: [
          { actor_id: 1, voice_id: "voice_1" },
          { actor_id: 2, voice_id: "voice_2" }
        ]
      }
    end

    let(:expected_response) do
      {
        "data" => {
          "generation_id" => "multi_gen_789",
          "status" => "processing"
        }
      }
    end

    before do
      stub_request(:post, "#{base_url}/v1/shots/#{shot_id}/generate-multi-actor")
        .with(
          headers: { 'Authorization' => "Bearer #{api_key}" },
          body: {
            actors: [
              { actor_id: 1, voice_id: "voice_1" },
              { actor_id: 2, voice_id: "voice_2" }
            ]
          }.to_json
        )
        .to_return(status: 201, body: expected_response.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it "generates multi-actor LipDub" do
      response = shots.generate_multi_actor(**multi_actor_params)
      expect(response).to eq(expected_response)
    end
  end
end

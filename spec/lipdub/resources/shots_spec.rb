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

  describe "#validate_timecode_ranges" do
    context "with valid ranges" do
      it "validates numeric timecode ranges" do
        ranges = [[0, 10], [20, 30]]
        expect { shots.validate_timecode_ranges(ranges) }.not_to raise_error
      end

      it "validates SMPTE timecode ranges" do
        ranges = [["00:00:00:00", "00:00:10:00"], ["00:00:20:00", "00:00:30:00"]]
        expect { shots.validate_timecode_ranges(ranges) }.not_to raise_error
      end

      it "validates empty ranges" do
        expect { shots.validate_timecode_ranges([]) }.not_to raise_error
        expect { shots.validate_timecode_ranges(nil) }.not_to raise_error
      end

      it "validates with video duration constraint" do
        ranges = [[0, 10], [20, 30]]
        expect { shots.validate_timecode_ranges(ranges, video_duration: 60) }.not_to raise_error
      end
    end

    context "with invalid ranges" do
      it "raises error for non-array input" do
        expect { shots.validate_timecode_ranges("invalid") }.to raise_error(ArgumentError, /must be an array/)
      end

      it "raises error for invalid range format" do
        ranges = [[0, 10], [20]] # Missing end time
        expect { shots.validate_timecode_ranges(ranges) }.to raise_error(ArgumentError, /must be an array of \[start, end\]/)
      end

      it "raises error when start >= end" do
        ranges = [[10, 5]] # Start after end
        expect { shots.validate_timecode_ranges(ranges) }.to raise_error(ArgumentError, /Start time must be before end time/)
      end

      it "raises error when exceeding video duration" do
        ranges = [[0, 100]]
        expect { shots.validate_timecode_ranges(ranges, video_duration: 60) }.to raise_error(ArgumentError, /exceeds video duration/)
      end

      it "raises error for overlapping ranges" do
        ranges = [[0, 15], [10, 25]] # Overlapping at 10-15
        expect { shots.validate_timecode_ranges(ranges) }.to raise_error(ArgumentError, /Overlapping timecode ranges/)
      end
    end
  end

  describe "#parse_timecode_to_seconds" do
    it "parses numeric seconds" do
      expect(shots.parse_timecode_to_seconds(10.5)).to eq(10.5)
      expect(shots.parse_timecode_to_seconds(0)).to eq(0.0)
    end

    it "parses SMPTE format" do
      expect(shots.parse_timecode_to_seconds("00:00:10:15")).to eq(10.5) # 10s + 15/30 frames
      expect(shots.parse_timecode_to_seconds("00:01:30:00")).to eq(90.0) # 1 min 30s
      expect(shots.parse_timecode_to_seconds("01:00:00:00")).to eq(3600.0) # 1 hour
    end

    it "parses string numbers" do
      expect(shots.parse_timecode_to_seconds("10.5")).to eq(10.5)
      expect(shots.parse_timecode_to_seconds("0")).to eq(0.0)
    end

    it "uses custom fps for SMPTE" do
      expect(shots.parse_timecode_to_seconds("00:00:10:12", fps: 24)).to eq(10.5) # 10s + 12/24 frames
    end

    it "raises error for invalid format" do
      expect { shots.parse_timecode_to_seconds({}) }.to raise_error(ArgumentError, /Invalid timecode format/)
    end
  end

  describe "#add_frame_buffer" do
    it "adds buffer to numeric ranges" do
      ranges = [[10, 20], [30, 40]]
      buffer_seconds = 10.0 / 30 # 10 frames at 30fps
      
      result = shots.add_frame_buffer(ranges, buffer_frames: 10, fps: 30)
      
      expect(result).to eq([
        [10 - buffer_seconds, 20 + buffer_seconds],
        [30 - buffer_seconds, 40 + buffer_seconds]
      ])
    end

    it "clamps start time to 0" do
      ranges = [[0.5, 15]] # Start close to 0
      buffer_seconds = 20.0 / 30 # 20 frames at 30fps ≈ 0.667
      
      result = shots.add_frame_buffer(ranges, buffer_frames: 20, fps: 30)
      
      expect(result[0][0]).to eq(0) # Start clamped to 0 (0.5 - 0.667 = -0.167, clamped to 0)
      expect(result[0][1]).to eq(15 + buffer_seconds) # End extended
    end

    it "clamps end time to video duration" do
      ranges = [[50, 59.8]] # End close to duration
      buffer_seconds = 10.0 / 30 # 10 frames at 30fps ≈ 0.333
      
      result = shots.add_frame_buffer(ranges, buffer_frames: 10, fps: 30, video_duration: 60)
      
      expect(result[0][1]).to eq(60) # End clamped to video duration (59.8 + 0.333 = 60.133, clamped to 60)
    end

    it "handles SMPTE timecodes" do
      ranges = [["00:00:10:00", "00:00:20:00"]]
      
      result = shots.add_frame_buffer(ranges, buffer_frames: 15, fps: 30)
      
      expect(result[0][0]).to eq(9.5) # 10 - 15/30
      expect(result[0][1]).to eq(20.5) # 20 + 15/30
    end

    it "returns original ranges if nil or empty" do
      expect(shots.add_frame_buffer(nil)).to be_nil
      expect(shots.add_frame_buffer([])).to eq([])
    end
  end

  describe "selective lip-dubbing workflow" do
    it "generates with timecode ranges for selective lip-dubbing" do
      shot_id = 123
      params = {
        audio_id: "audio_123",
        output_filename: "selective.mp4",
        timecode_ranges: [[0, 10], [20, 30]]
      }

      stub_request(:post, "#{base_url}/v1/shots/#{shot_id}/generate")
        .with(body: params.to_json)
        .to_return(status: 200, body: { generate_id: 456 }.to_json, headers: { 'Content-Type' => 'application/json' })

      response = shots.generate(shot_id: shot_id, **params)
      expect(response).to eq({ "generate_id" => 456 })
    end

    it "validates and buffers timecode ranges in workflow" do
      ranges = [[10, 20], [40, 50]]
      
      # Validate first
      expect { shots.validate_timecode_ranges(ranges, video_duration: 60) }.not_to raise_error
      
      # Add buffer
      buffered = shots.add_frame_buffer(ranges, buffer_frames: 10, fps: 30)
      
      expect(buffered.length).to eq(2)
      expect(buffered[0][0]).to be < 10 # Start buffered back
      expect(buffered[0][1]).to be > 20 # End buffered forward
    end
  end
end

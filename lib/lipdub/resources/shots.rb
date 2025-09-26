# frozen_string_literal: true

require 'fileutils'

module Lipdub
  module Resources
    class Shots < Base
      # List all available shots
      #
      # @param page [Integer] Page number for pagination (defaults to 1)
      # @param per_page [Integer] Number of items per page, max 100 (defaults to 20)
      # @return [Hash] Response containing list of shots and count
      #
      # @example
      #   shots = client.shots.list(page: 1, per_page: 50)
      #   # => {
      #   #   "data" => [
      #   #     {
      #   #       "shot_id" => 99,
      #   #       "shot_label" => "api-full-test-new.mp4",
      #   #       "shot_project_id" => 37,
      #   #       "shot_scene_id" => 37,
      #   #       "shot_project_name" => "Lee Studios",
      #   #       "shot_scene_name" => "Under the tent"
      #   #     }
      #   #   ],
      #   #   "count" => 1
      #   # }
      def list(page: 1, per_page: 20)
        validate_pagination_params!(page, per_page)
        
        params = {
          page: page,
          per_page: per_page
        }
        get("/v1/shots", params)
      end

      # Get shot processing status
      #
      # @param shot_id [String, Integer] Unique identifier of the shot
      # @return [Hash] Response containing shot status and processing information
      #
      # @example
      #   status = client.shots.status(123)
      def status(shot_id)
        get("/v1/shots/#{shot_id}/status")
      end

      # Generate lip-dubbed video
      #
      # @param shot_id [String, Integer] Unique identifier of the shot
      # @param audio_id [String] Unique identifier of the audio file
      # @param output_filename [String] Name for the output file
      # @param language [String, nil] Optional language specification (ISO 639-1)
      # @param start_frame [Integer, nil] Frame number to start the lip-sync from (defaults to 0)
      # @param loop_video [Boolean, nil] Whether to loop the video during rendering (defaults to false)
      # @param full_resolution [Boolean, nil] Whether to use full resolution (defaults to true)
      # @param callback_url [String, nil] Optional HTTPS URL for completion callback
      # @param timecode_ranges [Array, nil] Optional list of timecode ranges to render
      # @return [Hash] Response containing generation details and generate_id
      #
      # @example
      #   response = client.shots.generate(
      #     shot_id: 123,
      #     audio_id: "audio_456",
      #     output_filename: "dubbed_video.mp4",
      #     language: "en-US",
      #     start_frame: 0,
      #     loop_video: false,
      #     full_resolution: true,
      #     callback_url: "https://example.com/webhook"
      #   )
      #   # => {
      #   #   "generate_id" => 456
      #   # }
      def generate(shot_id:, audio_id:, output_filename:, language: nil, start_frame: nil, 
                   loop_video: nil, full_resolution: nil, callback_url: nil, timecode_ranges: nil)
        body = {
          audio_id: audio_id,
          output_filename: output_filename
        }
        
        body[:language] = language if language
        body[:start_frame] = start_frame if start_frame
        body[:loop_video] = loop_video unless loop_video.nil?
        body[:full_resolution] = full_resolution unless full_resolution.nil?
        body[:callback_url] = callback_url if callback_url
        body[:timecode_ranges] = timecode_ranges if timecode_ranges

        post("/v1/shots/#{shot_id}/generate", body)
      end

      # Get generation status
      #
      # @param shot_id [String, Integer] Unique identifier of the shot
      # @param generate_id [String] Unique identifier of the generation request
      # @return [Hash] Response containing generation progress and status
      #
      # @example
      #   status = client.shots.generation_status(123, "gen_789")
      def generation_status(shot_id, generate_id)
        get("/v1/shots/#{shot_id}/generate/#{generate_id}")
      end

      # Download generated video
      #
      # @param shot_id [String, Integer] Unique identifier of the shot
      # @param generate_id [String] Unique identifier of the generation request
      # @return [Hash] Response containing download_url for the dubbed video
      #
      # @example
      #   download_info = client.shots.download(123, "gen_789")
      #   # => {
      #   #   "data" => {
      #   #     "download_url" => "https://storage.lipdub.ai/download/gen_789?token=xyz"
      #   #   }
      #   # }
      def download(shot_id, generate_id)
        get("/v1/shots/#{shot_id}/generate/#{generate_id}/download")
      end

      # Download generated video file directly to a local path
      #
      # @param shot_id [String, Integer] Unique identifier of the shot
      # @param generate_id [String] Unique identifier of the generation request
      # @param file_path [String] Local path where the video should be saved
      # @return [String] Path to the downloaded file
      #
      # @example
      #   local_path = client.shots.download_file(123, "gen_789", "output/dubbed_video.mp4")
      #   # Downloads the file and returns "output/dubbed_video.mp4"
      def download_file(shot_id, generate_id, file_path)
        download_response = download(shot_id, generate_id)
        download_url = download_response.dig("data", "download_url") if download_response.is_a?(Hash)
        
        # Handle case where response might still be a string (fallback)
        if download_response.is_a?(String)
          parsed = JSON.parse(download_response)
          download_url = parsed.dig("data", "download_url")
        end
        
        raise APIError, "Download URL not found in response" unless download_url

        download_file_from_url(download_url, file_path)
      end

      # Complete generation workflow: generate and wait for completion
      #
      # @param shot_id [String, Integer] Unique identifier of the shot
      # @param audio_id [String] Unique identifier of the audio file
      # @param output_filename [String] Name for the output file
      # @param language [String, nil] Optional language specification (ISO 639-1)
      # @param start_frame [Integer, nil] Frame number to start the lip-sync from (defaults to 0)
      # @param loop_video [Boolean, nil] Whether to loop the video during rendering (defaults to false)
      # @param full_resolution [Boolean, nil] Whether to use full resolution (defaults to true)
      # @param callback_url [String, nil] Optional HTTPS URL for completion callback
      # @param timecode_ranges [Array, nil] Optional list of timecode ranges to render
      # @param polling_interval [Integer] Seconds to wait between status checks (default: 10)
      # @param max_wait_time [Integer] Maximum seconds to wait for completion (default: 1800)
      # @return [Hash] Response containing final generation status
      #
      # @example
      #   result = client.shots.generate_and_wait(
      #     shot_id: 123,
      #     audio_id: "audio_456",
      #     output_filename: "dubbed_video.mp4",
      #     polling_interval: 15,
      #     max_wait_time: 3600
      #   )
      def generate_and_wait(shot_id:, audio_id:, output_filename:, language: nil, 
                           start_frame: nil, loop_video: nil, full_resolution: nil, 
                           callback_url: nil, timecode_ranges: nil, polling_interval: 10, max_wait_time: 1800)
        # Start generation
        generate_response = generate(
          shot_id: shot_id,
          audio_id: audio_id,
          output_filename: output_filename,
          language: language,
          start_frame: start_frame,
          loop_video: loop_video,
          full_resolution: full_resolution,
          callback_url: callback_url,
          timecode_ranges: timecode_ranges
        )

        generate_id = nil
        if generate_response.is_a?(Hash)
          generate_id = generate_response["generate_id"] || generate_response.dig("data", "generate_id")
        elsif generate_response.is_a?(String)
          parsed = JSON.parse(generate_response)
          generate_id = parsed["generate_id"] || parsed.dig("data", "generate_id")
        end
        
        raise APIError, "Generate ID not found in response" unless generate_id

        # Poll for completion
        start_time = Time.now
        loop do
          status_response = generation_status(shot_id, generate_id)
          
          # Handle both Hash and String responses
          status = nil
          if status_response.is_a?(Hash)
            status = status_response.dig("data", "status") || status_response["status"]
          elsif status_response.is_a?(String)
            parsed = JSON.parse(status_response)
            status = parsed.dig("data", "status") || parsed["status"]
            status_response = parsed # Use parsed version for return
          end

          case status
          when "completed", "success"
            return status_response
          when "failed", "error"
            raise APIError, "Generation failed: #{status_response}"
          end

          # Check timeout
          if Time.now - start_time > max_wait_time
            raise TimeoutError, "Generation did not complete within #{max_wait_time} seconds"
          end

          sleep(polling_interval)
        end
      end

      # Get actors for a shot
      #
      # @param shot_id [String, Integer] Unique identifier of the shot
      # @return [Hash] Response containing actors information for the shot
      #
      # @example
      #   actors = client.shots.actors(123)
      def actors(shot_id)
        get("/v1/shots/#{shot_id}/actors")
      end

      # Translate a LipDub for a shot
      #
      # @param shot_id [String, Integer] Unique identifier of the shot
      # @param source_language [String] Source language code
      # @param target_language [String] Target language code
      # @param full_resolution [Boolean, nil] Whether to render in full resolution (defaults to true)
      # @return [Hash] Response containing translation details
      #
      # @example
      #   response = client.shots.translate(
      #     shot_id: 123,
      #     source_language: "English",
      #     target_language: "Spanish",
      #     full_resolution: true
      #   )
      def translate(shot_id:, source_language:, target_language:, full_resolution: nil)
        body = {
          source_language: source_language,
          target_language: target_language
        }
        body[:full_resolution] = full_resolution unless full_resolution.nil?

        post("/v1/shots/#{shot_id}/translate", body)
      end

      # Generate multi-actor LipDub for a shot
      #
      # @param shot_id [String, Integer] Unique identifier of the shot
      # @param params [Hash] Multi-actor generation parameters
      # @return [Hash] Response containing multi-actor generation details
      #
      # @example
      #   response = client.shots.generate_multi_actor(
      #     shot_id: 123,
      #     params: { actors: [...] }
      #   )
      def generate_multi_actor(shot_id:, **params)
        post("/v1/shots/#{shot_id}/generate-multi-actor", params)
      end

      private

      def validate_pagination_params!(page, per_page)
        raise ValidationError, "Page must be >= 1" if page < 1
        raise ValidationError, "Per page must be between 1 and 100" unless (1..100).include?(per_page)
      end

      def download_file_from_url(url, file_path)
        # Create directory if it doesn't exist
        FileUtils.mkdir_p(File.dirname(file_path))

        connection = Faraday.new do |conn|
          conn.adapter Faraday.default_adapter
        end

        response = connection.get(url)
        
        if response.success?
          File.open(file_path, 'wb') do |file|
            file.write(response.body)
          end
          file_path
        else
          raise APIError, "Failed to download file: HTTP #{response.status}"
        end
      end
    end
  end
end

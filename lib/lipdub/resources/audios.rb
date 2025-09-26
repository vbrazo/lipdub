# frozen_string_literal: true

module Lipdub
  module Resources
    class Audios < Base
      # Initiate audio upload process
      #
      # @param size_bytes [Integer] Size of the audio file in bytes (1 to 104857600)
      # @param file_name [String] Name of the audio file with extension
      # @param content_type [String] MIME type of the audio file (audio/mpeg, audio/wav, audio/mp4)
      # @param audio_source_url [String, nil] Optional URL of the audio source file
      # @return [Hash] Response containing audio_id, upload_url, success_url, and failure_url
      #
      # @example
      #   response = client.audios.upload(
      #     size_bytes: 5242880,
      #     file_name: "voiceover.mp3",
      #     content_type: "audio/mpeg"
      #   )
      #   # => {
      #   #   "data" => {
      #   #     "audio_id" => "audio_123",
      #   #     "upload_url" => "https://storage.lipdub.ai/upload/audio_123?token=xyz",
      #   #     "success_url" => "https://api.lipdub.ai/v1/audio/success/audio_123",
      #   #     "failure_url" => "https://api.lipdub.ai/v1/audio/failure/audio_123"
      #   #   }
      #   # }
      def upload(size_bytes:, file_name:, content_type:, audio_source_url: nil)
        validate_audio_params!(size_bytes, content_type)
        
        body = {
          size_bytes: size_bytes,
          file_name: file_name,
          content_type: content_type
        }
        body[:audio_source_url] = audio_source_url if audio_source_url

        post("/v1/audio", body)
      end

      # Upload audio file to the provided upload URL
      #
      # @param upload_url [String] The upload URL received from the upload method
      # @param file_content [String, IO] The audio file content to upload
      # @param content_type [String] MIME type of the audio file
      # @return [Hash] Response from the upload
      #
      # @example
      #   file_content = File.read("voiceover.mp3")
      #   client.audios.upload_file(upload_url, file_content, "audio/mpeg")
      def upload_file(upload_url, file_content, content_type)
        put_file(upload_url, file_content, content_type)
      end

      # Complete audio upload process with a file path
      #
      # @param file_path [String] Path to the audio file
      # @param content_type [String, nil] MIME type of the audio file (auto-detected if nil)
      # @return [Hash] Response after successful upload
      #
      # @example
      #   response = client.audios.upload_complete("path/to/audio.mp3")
      #   # This method handles the entire upload flow:
      #   # 1. Initiates upload
      #   # 2. Uploads the file
      #   # 3. Calls success callback
      def upload_complete(file_path, content_type: nil)
        raise ArgumentError, "File does not exist: #{file_path}" unless File.exist?(file_path)

        file_content = File.read(file_path)
        file_name = File.basename(file_path)
        content_type ||= detect_content_type(file_path)
        size_bytes = File.size(file_path)

        # Step 1: Initiate upload
        upload_response = upload(
          size_bytes: size_bytes,
          file_name: file_name,
          content_type: content_type
        )

        audio_id = upload_response.dig("data", "audio_id") if upload_response.is_a?(Hash)
        upload_url = upload_response.dig("data", "upload_url") if upload_response.is_a?(Hash)
        
        # Handle case where response might still be a string (fallback)
        if upload_response.is_a?(String)
          parsed = JSON.parse(upload_response)
          audio_id = parsed.dig("data", "audio_id")
          upload_url = parsed.dig("data", "upload_url")
        end
        
        begin
          # Step 2: Upload file
          upload_file(upload_url, file_content, content_type)
          
          # Step 3: Mark as successful
          success(audio_id)
        rescue => e
          # Step 3 (alternative): Mark as failed
          failure(audio_id)
          raise e
        end
      end

      # Mark audio upload as successful
      #
      # @param audio_id [String] Unique identifier of the audio file
      # @return [Hash] Response (typically empty)
      #
      # @example
      #   client.audios.success("audio_123")
      def success(audio_id)
        post("/v1/audio/success/#{audio_id}")
      end

      # Mark audio upload as failed
      #
      # @param audio_id [String] Unique identifier of the audio file
      # @return [Hash] Response (typically empty)
      #
      # @example
      #   client.audios.failure("audio_123")
      def failure(audio_id)
        post("/v1/audio/failure/#{audio_id}")
      end

      # Get audio processing status
      #
      # @param audio_id [String] Unique identifier of the audio file
      # @return [Hash] Response containing audio status information
      #
      # @example
      #   status = client.audios.status("audio_123")
      def status(audio_id)
        get("/v1/audio/status/#{audio_id}")
      end

      # List all audio files
      #
      # @param page [Integer] Page number (defaults to 1)
      # @param page_size [Integer] Number of items per page (defaults to 10)
      # @return [Hash] Response containing list of audio files
      #
      # @example
      #   audios = client.audios.list(page: 1, page_size: 20)
      def list(page: 1, page_size: 10)
        params = {
          page: page,
          page_size: page_size
        }
        get("/v1/audio", params)
      end

      private

      def validate_audio_params!(size_bytes, content_type)
        unless (1..104857600).include?(size_bytes)
          raise ValidationError, "Audio file size must be between 1 and 104857600 bytes"
        end

        valid_types = %w[audio/mpeg audio/wav audio/mp4]
        unless valid_types.include?(content_type)
          raise ValidationError, "Content type must be one of: #{valid_types.join(', ')}"
        end
      end

      def detect_content_type(file_path)
        extension = File.extname(file_path).downcase
        case extension
        when '.mp3'
          'audio/mpeg'
        when '.wav'
          'audio/wav'
        when '.mp4', '.m4a'
          'audio/mp4'
        else
          'audio/mpeg' # Default fallback
        end
      end
    end
  end
end

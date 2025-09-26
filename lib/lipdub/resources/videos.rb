# frozen_string_literal: true

module Lipdub
  module Resources
    class Videos < Base
      # Initiate video upload process
      #
      # @param size_bytes [Integer] Size of the video file in bytes
      # @param file_name [String] Name of the video file with extension
      # @param content_type [String] MIME type of the video file
      # @param video_source_url [String, nil] Optional URL of the video source file
      # @return [Hash] Response containing video_id, upload_url, success_url, and failure_url
      #
      # @example
      #   response = client.videos.upload(
      #     size_bytes: 52428800,
      #     file_name: "sample.mp4",
      #     content_type: "video/mp4"
      #   )
      #   # => {
      #   #   "data" => {
      #   #     "video_id" => "video_123",
      #   #     "upload_url" => "https://storage.lipdub.ai/upload/video_123?token=xyz",
      #   #     "success_url" => "https://api.lipdub.ai/v1/video/success/video_123",
      #   #     "failure_url" => "https://api.lipdub.ai/v1/video/failure/video_123"
      #   #   }
      #   # }
      def upload(size_bytes:, file_name:, content_type:, video_source_url: nil)
        body = {
          size_bytes: size_bytes,
          file_name: file_name,
          content_type: content_type
        }
        body[:video_source_url] = video_source_url if video_source_url

        post("/v1/video", body)
      end

      # Upload video file to the provided upload URL
      #
      # @param upload_url [String] The upload URL received from the upload method
      # @param file_content [String, IO] The video file content to upload
      # @param content_type [String] MIME type of the video file
      # @return [Hash] Response from the upload
      #
      # @example
      #   file_content = File.read("sample.mp4")
      #   client.videos.upload_file(upload_url, file_content, "video/mp4")
      def upload_file(upload_url, file_content, content_type)
        put_file(upload_url, file_content, content_type)
      end

      # Complete video upload process with a file path
      #
      # @param file_path [String] Path to the video file
      # @param content_type [String, nil] MIME type of the video file (auto-detected if nil)
      # @return [Hash] Response containing shot_id and asset_type after successful upload
      #
      # @example
      #   response = client.videos.upload_complete("path/to/video.mp4")
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

        video_id = upload_response.dig("data", "video_id") if upload_response.is_a?(Hash)
        upload_url = upload_response.dig("data", "upload_url") if upload_response.is_a?(Hash)
        
        # Handle case where response might still be a string (fallback)
        if upload_response.is_a?(String)
          parsed = JSON.parse(upload_response)
          video_id = parsed.dig("data", "video_id")
          upload_url = parsed.dig("data", "upload_url")
        end
        
        begin
          # Step 2: Upload file
          upload_file(upload_url, file_content, content_type)
          
          # Step 3: Mark as successful
          success(video_id)
        rescue => e
          # Step 3 (alternative): Mark as failed
          failure(video_id)
          raise e
        end
      end

      # Mark video upload as successful
      #
      # @param video_id [String] Unique identifier of the video file
      # @return [Hash] Response containing shot_id and asset_type
      #
      # @example
      #   response = client.videos.success("video_123")
      #   # => {
      #   #   "data" => {
      #   #     "shot_id" => 123,
      #   #     "asset_type" => "dubbing-video"
      #   #   }
      #   # }
      def success(video_id)
        post("/v1/video/success/#{video_id}")
      end

      # Mark video upload as failed
      #
      # @param video_id [String] Unique identifier of the video file
      # @return [Hash] Response (typically empty)
      #
      # @example
      #   client.videos.failure("video_123")
      def failure(video_id)
        post("/v1/video/failure/#{video_id}")
      end

      # Get video processing status
      #
      # @param video_id [String] Unique identifier of the video file
      # @return [Hash] Response containing video status information
      #
      # @example
      #   status = client.videos.status("video_123")
      def status(video_id)
        get("/v1/video/status/#{video_id}")
      end

      private

      def detect_content_type(file_path)
        extension = File.extname(file_path).downcase
        case extension
        when '.mp4'
          'video/mp4'
        when '.mov'
          'video/quicktime'
        when '.avi'
          'video/x-msvideo'
        when '.webm'
          'video/webm'
        when '.mkv'
          'video/x-matroska'
        else
          'video/mp4' # Default fallback
        end
      end
    end
  end
end

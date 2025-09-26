# Lipdub Ruby Client

A comprehensive Ruby client library for the [Lipdub.ai API](https://lipdub.ai), providing easy access to AI-powered lip-dubbing functionality.

[![Gem Version](https://badge.fury.io/rb/lipdub.svg)](https://badge.fury.io/rb/lipdub)
[![Build Status](https://github.com/upriser/lipdub-ruby/workflows/CI/badge.svg)](https://github.com/upriser/lipdub-ruby/actions)
[![Security](https://img.shields.io/badge/security-bundler--audit-blue.svg)](https://github.com/rubysec/bundler-audit)

## Features

- **Video Upload**: Upload and process videos for lip-dubbing
- **Audio Upload**: Upload audio files for voice replacement
- **Generation**: Generate lip-dubbed videos with AI
- **Status Monitoring**: Track processing and generation progress
- **File Management**: Handle file uploads and downloads seamlessly
- **Error Handling**: Comprehensive error handling with custom exceptions
- **Test Coverage**: Full test suite with RSpec

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'lipdub'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install lipdub

## Configuration

Configure the client with your API key:

```ruby
require 'lipdub'

# Global configuration
Lipdub.configure do |config|
  config.api_key = "your_api_key_here"
  config.base_url = "https://api.lipdub.ai"  # Optional, this is the default
  config.timeout = 30                        # Optional, default is 30 seconds
  config.open_timeout = 10                   # Optional, default is 10 seconds
end

# Or create a client with specific configuration
config = Lipdub::Configuration.new
config.api_key = "your_api_key_here"
client = Lipdub::Client.new(config)
```

## Usage

### Video Upload

#### Simple Video Upload

```ruby
client = Lipdub.client

# Upload a video file (handles the entire workflow)
response = client.videos.upload_complete("path/to/your/video.mp4")
# => {
#   "data" => {
#     "shot_id" => 123,
#     "asset_type" => "dubbing-video"
#   }
# }

shot_id = response.dig("data", "shot_id")
```

#### Manual Video Upload Process

```ruby
# Step 1: Initiate upload
upload_response = client.videos.upload(
  size_bytes: File.size("video.mp4"),
  file_name: "my_video.mp4",
  content_type: "video/mp4"
)

video_id = upload_response.dig("data", "video_id")
upload_url = upload_response.dig("data", "upload_url")

# Step 2: Upload the file
file_content = File.read("video.mp4")
client.videos.upload_file(upload_url, file_content, "video/mp4")

# Step 3: Mark as successful
success_response = client.videos.success(video_id)
shot_id = success_response.dig("data", "shot_id")
```

#### Check Video Status

```ruby
status = client.videos.status(video_id)
# => {
#   "data" => {
#     "status" => "processing",
#     "progress" => 50
#   }
# }
```

### Audio Upload

#### Simple Audio Upload

```ruby
# Upload an audio file (handles the entire workflow)
response = client.audios.upload_complete("path/to/your/audio.mp3")

# Get the audio_id for generation
audio_id = response.dig("data", "audio_id")
```

#### Manual Audio Upload Process

```ruby
# Step 1: Initiate upload
upload_response = client.audios.upload(
  size_bytes: File.size("audio.mp3"),
  file_name: "voiceover.mp3",
  content_type: "audio/mpeg"
)

audio_id = upload_response.dig("data", "audio_id")
upload_url = upload_response.dig("data", "upload_url")

# Step 2: Upload the file
file_content = File.read("audio.mp3")
client.audios.upload_file(upload_url, file_content, "audio/mpeg")

# Step 3: Mark as successful
client.audios.success(audio_id)
```

#### List Audio Files

```ruby
# List all audio files
audios = client.audios.list(page: 1, page_size: 20)
# => {
#   "data" => [
#     { "audio_id" => "audio_1", "file_name" => "voice1.mp3" },
#     { "audio_id" => "audio_2", "file_name" => "voice2.wav" }
#   ],
#   "pagination" => { "page" => 1, "page_size" => 20, "total" => 50 }
# }
```

### Shot Management

#### List Available Shots

```ruby
# List all shots
shots = client.shots.list(page: 1, per_page: 50)
# => {
#   "data" => [
#     {
#       "shot_id" => 99,
#       "shot_label" => "api-full-test-new.mp4",
#       "shot_project_id" => 37,
#       "shot_scene_id" => 37,
#       "shot_project_name" => "Lee Studios",
#       "shot_scene_name" => "Under the tent"
#     }
#   ],
#   "count" => 1
# }
```

#### Get Shot Actors

```ruby
# Get actors for a specific shot
actors = client.shots.actors(shot_id)
```

### Shot Generation

#### Generate Lip-Dubbed Video

```ruby
# Start generation with all available options
generate_response = client.shots.generate(
  shot_id: shot_id,
  audio_id: audio_id,
  output_filename: "final_dubbed_video.mp4",
  language: "en-US",                 # Optional (ISO 639-1)
  start_frame: 0,                    # Optional
  loop_video: false,                 # Optional
  full_resolution: true,             # Optional
  callback_url: "https://example.com/webhook", # Optional
  timecode_ranges: [[0, 100], [200, 300]]     # Optional
)

generate_id = generate_response["generate_id"]
```

#### Selective Lip-dubbing for Single Actors

For scenarios where you only want to lip-dub specific parts of a video (e.g., personalization where only a name needs to be replaced), you can use selective lip-dubbing with `timecode_ranges`:

```ruby
# Basic selective lip-dubbing with time ranges in seconds
response = client.shots.generate(
  shot_id: 123,
  audio_id: "audio_abc123",
  output_filename: "personalized_video.mp4",
  timecode_ranges: [[0, 10], [20, 30]] # Replace seconds 0-10 and 20-30
)

# With SMPTE timecode format (be consistent with format)
response = client.shots.generate(
  shot_id: 123,
  audio_id: "audio_abc123", 
  output_filename: "personalized_video.mp4",
  timecode_ranges: [["00:00:00:00", "00:00:10:00"], ["00:00:20:00", "00:00:30:00"]]
)

# Example: Replace a name greeting with proper buffering
# Calculate 10-frame buffer (assuming 30fps: 10/30 = 0.33 seconds)
name_start = 2.5 - 0.33  # Start 10 frames before
name_end = 4.2 + 0.33    # End 10 frames after

response = client.shots.generate(
  shot_id: 123,
  audio_id: "audio_with_new_name",
  output_filename: "personalized_greeting.mp4", 
  timecode_ranges: [[name_start, name_end]],
  language: "en-US"
)
```

##### Best Practices for Selective Lip-dubbing

1. **Match Original Region Length**: Ensure replaced audio regions match the original region length to maintain sync
2. **Add Frame Buffer**: Include a 10-frame buffer around start/end timecodes for seamless blending  
3. **Normalize Audio**: Normalize audio levels and isolate vocals from background noise for best results
4. **Audio Duration**: The total audio duration must match the video duration
5. **Consistent Timecode Format**: Use either seconds (float) or SMPTE format consistently
6. **Non-overlapping Ranges**: Ensure timecode ranges don't overlap each other

#### Translation

```ruby
# Translate a shot to different language
translation = client.shots.translate(
  shot_id: shot_id,
  source_language: "English",
  target_language: "Spanish",
  full_resolution: true              # Optional
)
```

#### Multi-Actor Generation

```ruby
# Generate with multiple actors
multi_result = client.shots.generate_multi_actor(
  shot_id: shot_id,
  actors: [
    { actor_id: 1, voice_id: "voice_1" },
    { actor_id: 2, voice_id: "voice_2" }
  ]
)
```

#### Monitor Generation Progress

```ruby
# Check generation status
status = client.shots.generation_status(shot_id, generate_id)
# => {
#   "data" => {
#     "generate_id" => "gen_789",
#     "status" => "processing",
#     "progress" => 75
#   }
# }
```

#### Generate and Wait for Completion

```ruby
# Generate and automatically wait for completion
result = client.shots.generate_and_wait(
  shot_id: shot_id,
  audio_id: audio_id,
  output_filename: "dubbed_video.mp4",
  polling_interval: 10,    # Check every 10 seconds
  max_wait_time: 1800     # Wait up to 30 minutes
)
# => Returns when generation is complete or raises an error
```

#### Download Generated Video

```ruby
# Get download URL
download_info = client.shots.download(shot_id, generate_id)
download_url = download_info.dig("data", "download_url")

# Or download directly to a file
local_path = client.shots.download_file(
  shot_id, 
  generate_id, 
  "output/my_dubbed_video.mp4"
)
```

### Project Management

#### List Projects

```ruby
# List all projects
projects = client.projects.list(page: 1, per_page: 20)
# => {
#   "data" => [
#     {
#       "project_id" => 123,
#       "projects_tenant_id" => 1,
#       "projects_user_id" => 47,
#       "project_name" => "My Sample Project",
#       "user_email" => "user@example.com",
#       "created_at" => "2024-01-15T10:30:00Z",
#       "updated_at" => nil,
#       "source_language" => {
#         "language_id" => 1,
#         "name" => "English",
#         "supported" => true
#       },
#       "project_identity_type" => "single_identity",
#       "language_project_links" => []
#     }
#   ],
#   "count" => 1
# }
```

### Complete Workflow Examples

#### Basic Lip-dubbing Workflow

Here's a complete example that uploads a video and audio, generates a lip-dubbed video, and downloads the result:

```ruby
require 'lipdub'

# Configure the client
Lipdub.configure do |config|
  config.api_key = "your_api_key_here"
end

client = Lipdub.client

begin
  # 0. List existing projects and shots (optional)
  puts "Listing projects..."
  projects = client.projects.list
  puts "Found #{projects['count']} projects"
  
  puts "Listing available shots..."
  shots = client.shots.list
  puts "Found #{shots['count']} shots"

  # 1. Upload video
  puts "Uploading video..."
  video_response = client.videos.upload_complete("input/original_video.mp4")
  shot_id = video_response.dig("data", "shot_id")
  puts "Video uploaded, shot_id: #{shot_id}"

  # 2. Upload audio
  puts "Uploading audio..."
  audio_response = client.audios.upload_complete("input/new_voice.mp3")
  audio_id = audio_response.dig("data", "audio_id") || "audio_from_upload"
  puts "Audio uploaded, audio_id: #{audio_id}"

  # 3. Generate lip-dubbed video
  puts "Starting generation..."
  result = client.shots.generate_and_wait(
    shot_id: shot_id,
    audio_id: audio_id,
    output_filename: "dubbed_output.mp4",
    language: "en",
    maintain_expression: true,
    polling_interval: 15,
    max_wait_time: 3600  # 1 hour
  )

  generate_id = result.dig("data", "generate_id")
  puts "Generation complete, generate_id: #{generate_id}"

  # 4. Download the result
  puts "Downloading result..."
  output_path = client.shots.download_file(
    shot_id,
    generate_id,
    "output/final_dubbed_video.mp4"
  )
  puts "Video downloaded to: #{output_path}"
```

#### Selective Lip-dubbing Workflow

Here's an example showing how to use selective lip-dubbing for personalization (e.g., replacing just a name in a greeting):

```ruby
require 'lipdub'

# Configure the client
Lipdub.configure do |config|
  config.api_key = "your_api_key_here"
end

client = Lipdub.client

begin
  # 1. Upload original video (done once)
  video_response = client.videos.upload_complete(
    file_path: "./original_greeting.mp4",
    content_type: "video/mp4"
  )
  video_id = video_response.dig("data", "video_id")

  # 2. Upload personalized audio (replace original audio with new name)
  # NOTE: Audio duration must match the video duration exactly
  personalized_audio = client.audios.upload_complete(
    file_path: "./personalized_greeting_audio.mp3", # Contains new name
    content_type: "audio/mp3"
  )
  audio_id = personalized_audio.dig("data", "audio_id")

  # 3. Wait for video processing and get shot_id
  loop do
    status = client.videos.status(video_id: video_id)
    if status.dig("data", "status") == "success"
      shot_id = status.dig("data", "shot_id")
      break
    elsif status.dig("data", "status") == "failed"
      raise "Video processing failed"
    end
    sleep 5
  end

  # 4. Define timecode ranges for selective replacement
  # Example: Replace name at 2.5-4.2 seconds with 10-frame buffer
  name_start = 2.5
  name_end = 4.2

  # Use helper method to add frame buffer (recommended)
  timecode_ranges = client.shots.add_frame_buffer(
    [[name_start, name_end]], 
    buffer_frames: 10, 
    fps: 30
  )

  # Validate ranges (optional but recommended)
  client.shots.validate_timecode_ranges(
    timecode_ranges, 
    video_duration: 30.0 # Your video duration
  )

  # 5. Generate selective lip-dub
  generation = client.shots.generate(
    shot_id: shot_id,
    audio_id: audio_id,
    output_filename: "personalized_greeting.mp4",
    timecode_ranges: timecode_ranges, # Only lip-dub the name part
    language: "en-US"
  )

  generate_id = generation["generate_id"]

  # 6. Wait for generation to complete and download
  client.shots.download_file(
    shot_id,
    generate_id,
    "output/personalized_greeting.mp4"
  )

  puts "Personalized video with selective lip-dubbing saved!"

  # Alternative: Multiple selective ranges (e.g., name + closing)
  multiple_ranges = [
    [2.5, 4.2],   # Name replacement
    [25.0, 27.5]  # Closing replacement
  ]

  buffered_ranges = client.shots.add_frame_buffer(
    multiple_ranges,
    buffer_frames: 10,
    fps: 30,
    video_duration: 30.0
  )

  # Generate with multiple selective ranges
  multi_selective = client.shots.generate(
    shot_id: shot_id,
    audio_id: audio_id,
    output_filename: "multi_personalized.mp4",
    timecode_ranges: buffered_ranges
  )

rescue Lipdub::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue Lipdub::ValidationError => e
  puts "Validation error: #{e.message}"
rescue Lipdub::TimeoutError => e
  puts "Request timed out: #{e.message}"
rescue Lipdub::APIError => e
  puts "API error (#{e.status_code}): #{e.message}"
rescue => e
  puts "Unexpected error: #{e.message}"
end
```

## Supported File Formats

### Video Formats
- MP4 (recommended: 1080p HD, 23.976 fps, H.264 codec)
- MOV
- AVI
- WebM
- MKV

### Audio Formats
- MP3 (audio/mpeg)
- WAV (audio/wav)
- MP4/M4A (audio/mp4)

## Error Handling

The gem provides comprehensive error handling with specific exception types:

```ruby
begin
  client.videos.upload_complete("video.mp4")
rescue Lipdub::AuthenticationError => e
  # API key is invalid or missing
  puts "Authentication failed: #{e.message}"
rescue Lipdub::ValidationError => e
  # Request parameters are invalid
  puts "Validation error: #{e.message}"
  puts "Status code: #{e.status_code}"
  puts "Response body: #{e.response_body}"
rescue Lipdub::NotFoundError => e
  # Resource not found
  puts "Resource not found: #{e.message}"
rescue Lipdub::RateLimitError => e
  # Rate limit exceeded
  puts "Rate limit exceeded: #{e.message}"
rescue Lipdub::ServerError => e
  # Server error (5xx)
  puts "Server error: #{e.message}"
rescue Lipdub::TimeoutError => e
  # Request timed out
  puts "Request timed out: #{e.message}"
rescue Lipdub::ConnectionError => e
  # Connection failed
  puts "Connection failed: #{e.message}"
rescue Lipdub::APIError => e
  # Generic API error
  puts "API error: #{e.message}"
rescue Lipdub::ConfigurationError => e
  # Configuration is invalid
  puts "Configuration error: #{e.message}"
end
```

## Development

After checking out the repo, run:

```bash
bin/setup
```

To install dependencies. Then, run:

```bash
rake spec
```

To run the tests. You can also run:

```bash
bin/console
```

For an interactive prompt that will allow you to experiment.

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/lipdub/client_spec.rb

# Run tests with coverage
bundle exec rspec --format documentation

# Run security audit
bundle exec rake audit

# Run all CI checks (tests + security audit)
bundle exec rake ci

# Optional: Run rubocop for linting (not included in CI)
bundle exec rubocop
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/upriser/lipdub-ruby.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Make your changes and add tests
4. Run the test suite (`bundle exec rake ci`)
5. Ensure security audit passes (`bundle exec rake audit`)
6. Commit your changes (`git commit -am 'Add some feature'`)
7. Push to the branch (`git push origin my-new-feature`)
8. Create new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

# Lipdub Ruby Client

A comprehensive Ruby client library for the [Lipdub.ai API](https://lipdub.ai), providing easy access to AI-powered lip-dubbing functionality.

[![Gem Version](https://badge.fury.io/rb/lipdub.svg)](https://badge.fury.io/rb/lipdub)
[![Build Status](https://github.com/vbrazo/lipdub/workflows/CI/badge.svg)](https://github.com/upriser/lipdub-ruby/actions)
[![Security](https://img.shields.io/badge/security-bundler--audit-blue.svg)](https://github.com/rubysec/bundler-audit)

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Configuration](#configuration)
- [Quick Start](#quick-start)
- [API Reference](#api-reference)
  - [Videos](#videos)
  - [Audios](#audios)
  - [Shots](#shots)
  - [Projects](#projects)
- [Usage Examples](#usage-examples)
  - [Video Upload](#video-upload)
  - [Audio Upload](#audio-upload)
  - [Shot Management](#shot-management)
  - [Shot Generation](#shot-generation)
  - [Project Management](#project-management)
- [Complete Workflow Examples](#complete-workflow-examples)
  - [Basic Lip-dubbing Workflow](#basic-lip-dubbing-workflow)
  - [Selective Lip-dubbing Workflow](#selective-lip-dubbing-workflow)
- [Supported File Formats](#supported-file-formats)
- [Error Handling](#error-handling)
- [Rate Limits and Best Practices](#rate-limits-and-best-practices)
- [Troubleshooting](#troubleshooting)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

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

## Quick Start

Here's a minimal example to get you started with lip-dubbing:

```ruby
require 'lipdub'

# Configure the client
Lipdub.configure do |config|
  config.api_key = "your_api_key_here"
end

client = Lipdub.client

# Upload video and audio, then generate lip-dubbed video
video_response = client.videos.upload_complete("input/video.mp4")
shot_id = video_response.dig("data", "shot_id")

audio_response = client.audios.upload_complete("input/audio.mp3")
audio_id = audio_response.dig("data", "audio_id")

# Generate and download the result
result = client.shots.generate_and_wait(
  shot_id: shot_id,
  audio_id: audio_id,
  output_filename: "dubbed_video.mp4"
)

generate_id = result.dig("data", "generate_id")
client.shots.download_file(shot_id, generate_id, "output/result.mp4")
```

## API Reference

The Lipdub Ruby client provides four main resource classes for interacting with the API:

### Videos

The Videos resource handles video file uploads and processing.

#### Methods

| Method | Description | Parameters | Returns |
|--------|-------------|------------|---------|
| `upload(size_bytes:, file_name:, content_type:, video_source_url: nil)` | Initiate video upload process | `size_bytes` (Integer), `file_name` (String), `content_type` (String), `video_source_url` (String, optional) | Hash with `video_id`, `upload_url`, `success_url`, `failure_url` |
| `upload_file(upload_url, file_content, content_type)` | Upload video file to provided URL | `upload_url` (String), `file_content` (String/IO), `content_type` (String) | Hash |
| `upload_complete(file_path, content_type: nil)` | Complete upload workflow from file path | `file_path` (String), `content_type` (String, optional) | Hash with `shot_id` and `asset_type` |
| `success(video_id)` | Mark video upload as successful | `video_id` (String) | Hash with `shot_id` and `asset_type` |
| `failure(video_id)` | Mark video upload as failed | `video_id` (String) | Hash |
| `status(video_id)` | Get video processing status | `video_id` (String) | Hash with status information |

#### Endpoints

- `POST /v1/video` - Initiate video upload
- `POST /v1/video/success/{video_id}` - Mark upload successful
- `POST /v1/video/failure/{video_id}` - Mark upload failed
- `GET /v1/video/status/{video_id}` - Get processing status

### Audios

The Audios resource handles audio file uploads and management.

#### Methods

| Method | Description | Parameters | Returns |
|--------|-------------|------------|---------|
| `upload(size_bytes:, file_name:, content_type:, audio_source_url: nil)` | Initiate audio upload process | `size_bytes` (Integer, 1-104857600), `file_name` (String), `content_type` (String), `audio_source_url` (String, optional) | Hash with `audio_id`, `upload_url`, `success_url`, `failure_url` |
| `upload_file(upload_url, file_content, content_type)` | Upload audio file to provided URL | `upload_url` (String), `file_content` (String/IO), `content_type` (String) | Hash |
| `upload_complete(file_path, content_type: nil)` | Complete upload workflow from file path | `file_path` (String), `content_type` (String, optional) | Hash with upload result |
| `success(audio_id)` | Mark audio upload as successful | `audio_id` (String) | Hash |
| `failure(audio_id)` | Mark audio upload as failed | `audio_id` (String) | Hash |
| `status(audio_id)` | Get audio processing status | `audio_id` (String) | Hash with status information |
| `list(page: 1, page_size: 10)` | List all audio files | `page` (Integer), `page_size` (Integer) | Hash with audio list and pagination |

#### Endpoints

- `POST /v1/audio` - Initiate audio upload
- `POST /v1/audio/success/{audio_id}` - Mark upload successful
- `POST /v1/audio/failure/{audio_id}` - Mark upload failed
- `GET /v1/audio/status/{audio_id}` - Get processing status
- `GET /v1/audio` - List audio files

#### Supported Audio Formats

- `audio/mpeg` (MP3)
- `audio/wav` (WAV)
- `audio/mp4` (MP4/M4A)

### Shots

The Shots resource handles lip-dubbing generation, translation, and shot management.

#### Methods

| Method | Description | Parameters | Returns |
|--------|-------------|------------|---------|
| `list(page: 1, per_page: 20)` | List available shots | `page` (Integer), `per_page` (Integer, max 100) | Hash with shots list and count |
| `status(shot_id)` | Get shot processing status | `shot_id` (String/Integer) | Hash with status information |
| `generate(shot_id:, audio_id:, output_filename:, **options)` | Generate lip-dubbed video | See generation options below | Hash with `generate_id` |
| `generation_status(shot_id, generate_id)` | Get generation progress | `shot_id` (String/Integer), `generate_id` (String) | Hash with progress and status |
| `download(shot_id, generate_id)` | Get download URL for generated video | `shot_id` (String/Integer), `generate_id` (String) | Hash with `download_url` |
| `download_file(shot_id, generate_id, file_path)` | Download generated video to local path | `shot_id` (String/Integer), `generate_id` (String), `file_path` (String) | String (file path) |
| `generate_and_wait(shot_id:, audio_id:, output_filename:, **options)` | Generate and wait for completion | Same as generate + `polling_interval` (Integer), `max_wait_time` (Integer) | Hash with final status |
| `actors(shot_id)` | Get actors for a shot | `shot_id` (String/Integer) | Hash with actors information |
| `translate(shot_id:, source_language:, target_language:, full_resolution: nil)` | Translate a shot | `shot_id` (String/Integer), `source_language` (String), `target_language` (String), `full_resolution` (Boolean, optional) | Hash with translation details |
| `generate_multi_actor(shot_id:, **params)` | Generate multi-actor lip-dub | `shot_id` (String/Integer), `params` (Hash) | Hash with generation details |

#### Generation Options

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `shot_id` | String/Integer | **Required.** Unique identifier of the shot | - |
| `audio_id` | String | **Required.** Unique identifier of the audio file | - |
| `output_filename` | String | **Required.** Name for the output file | - |
| `language` | String | Language specification (ISO 639-1) | `nil` |
| `start_frame` | Integer | Frame number to start lip-sync from | `0` |
| `loop_video` | Boolean | Whether to loop video during rendering | `false` |
| `full_resolution` | Boolean | Whether to use full resolution | `true` |
| `callback_url` | String | HTTPS URL for completion callback | `nil` |
| `timecode_ranges` | Array | List of `[start, end]` timecode pairs for selective lip-dubbing | `nil` |

#### Timecode Ranges for Selective Lip-dubbing

Timecode ranges allow you to lip-dub only specific parts of a video:

```ruby
# Using seconds (float)
timecode_ranges: [[2.5, 4.2], [10.0, 12.5]]

# Using SMPTE format (HH:MM:SS:FF)
timecode_ranges: [["00:00:02:15", "00:00:04:06"], ["00:00:10:00", "00:00:12:15"]]
```

#### Helper Methods

| Method | Description | Parameters | Returns |
|--------|-------------|------------|---------|
| `validate_timecode_ranges(ranges, video_duration: nil)` | Validate timecode ranges | `ranges` (Array), `video_duration` (Numeric, optional) | Boolean or raises ArgumentError |
| `add_frame_buffer(ranges, buffer_frames: 10, fps: 30, video_duration: nil)` | Add frame buffer to ranges | `ranges` (Array), `buffer_frames` (Integer), `fps` (Integer), `video_duration` (Numeric, optional) | Array of buffered ranges |
| `parse_timecode_to_seconds(timecode, fps: 30)` | Convert timecode to seconds | `timecode` (String/Numeric), `fps` (Integer) | Float |

#### Endpoints

- `GET /v1/shots` - List shots
- `GET /v1/shots/{shot_id}/status` - Get shot status
- `POST /v1/shots/{shot_id}/generate` - Generate lip-dubbed video
- `GET /v1/shots/{shot_id}/generate/{generate_id}` - Get generation status
- `GET /v1/shots/{shot_id}/generate/{generate_id}/download` - Get download URL
- `GET /v1/shots/{shot_id}/actors` - Get shot actors
- `POST /v1/shots/{shot_id}/translate` - Translate shot
- `POST /v1/shots/{shot_id}/generate-multi-actor` - Multi-actor generation

### Projects

The Projects resource handles project management and listing.

#### Methods

| Method | Description | Parameters | Returns |
|--------|-------------|------------|---------|
| `list(page: 1, per_page: 20)` | List all projects | `page` (Integer), `per_page` (Integer, max 100) | Hash with projects list and count |

#### Endpoints

- `GET /v1/projects` - List projects

## Usage Examples

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
- **MP4** (recommended: 1080p HD, 23.976 fps, H.264 codec) - `video/mp4`
- **MOV** (QuickTime) - `video/quicktime`
- **AVI** (Audio Video Interleave) - `video/x-msvideo`
- **WebM** (Web Media) - `video/webm`
- **MKV** (Matroska Video) - `video/x-matroska`

### Audio Formats
- **MP3** (MPEG Audio Layer III) - `audio/mpeg` (1 byte to 100MB)
- **WAV** (Waveform Audio File Format) - `audio/wav` (1 byte to 100MB)
- **MP4/M4A** (MPEG-4 Audio) - `audio/mp4` (1 byte to 100MB)

### Recommendations
- **Video**: Use MP4 with H.264 codec for best compatibility and processing speed
- **Audio**: Use MP3 or WAV for optimal lip-sync results
- **Resolution**: 1080p HD recommended for best quality output
- **Frame Rate**: 23.976 fps or 30 fps for smooth lip-sync
- **Audio Quality**: 44.1kHz sample rate, 16-bit depth minimum

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

## Rate Limits and Best Practices

### Rate Limits
The Lipdub API implements rate limiting to ensure fair usage:
- **Upload endpoints**: 10 requests per minute
- **Generation endpoints**: 5 requests per minute  
- **Status/List endpoints**: 100 requests per minute

### Best Practices

#### Performance Optimization
- **Batch operations**: Upload multiple files before starting generation
- **Polling intervals**: Use appropriate intervals (10-30 seconds) when polling for status
- **File optimization**: Compress videos and normalize audio before upload
- **Concurrent uploads**: Upload video and audio files in parallel when possible

#### Error Handling
- **Retry logic**: Implement exponential backoff for transient errors
- **Validation**: Validate file formats and sizes before upload
- **Monitoring**: Log API responses for debugging and monitoring
- **Graceful degradation**: Handle API failures gracefully in production

#### Security
- **API key protection**: Store API keys securely (environment variables, secrets management)
- **HTTPS only**: All API communications use HTTPS
- **File validation**: Validate uploaded files on your end before sending to API
- **Webhook security**: Verify webhook signatures if using callback URLs

#### Resource Management
- **Cleanup**: Remove temporary files after processing
- **Storage**: Monitor storage usage for large video files
- **Timeouts**: Set appropriate timeouts for long-running operations
- **Memory**: Stream large files instead of loading entirely into memory

## Troubleshooting

### Common Issues

#### Upload Failures
```ruby
# Issue: File upload fails with timeout
# Solution: Increase timeout settings
Lipdub.configure do |config|
  config.timeout = 120        # 2 minutes for large files
  config.open_timeout = 30    # 30 seconds to establish connection
end
```

#### Generation Errors
```ruby
# Issue: Generation fails with validation error
# Solution: Validate inputs before generation
begin
  # Ensure audio duration matches video duration
  client.shots.validate_timecode_ranges(ranges, video_duration: 30.0)
  
  result = client.shots.generate(
    shot_id: shot_id,
    audio_id: audio_id,
    output_filename: "output.mp4"
  )
rescue Lipdub::ValidationError => e
  puts "Validation failed: #{e.message}"
  # Handle validation error
end
```

#### Network Issues
```ruby
# Issue: Connection timeouts or failures
# Solution: Implement retry logic with exponential backoff
def upload_with_retry(file_path, max_retries: 3)
  retries = 0
  begin
    client.videos.upload_complete(file_path)
  rescue Lipdub::TimeoutError, Lipdub::ConnectionError => e
    retries += 1
    if retries <= max_retries
      sleep(2 ** retries) # Exponential backoff
      retry
    else
      raise e
    end
  end
end
```

### Debug Mode

Enable debug logging to troubleshoot issues:

```ruby
# Enable debug logging (if supported by your HTTP client)
Lipdub.configure do |config|
  config.api_key = "your_api_key"
  config.debug = true  # Enable debug mode
end

# Or use a custom logger
require 'logger'
logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG

# Log API requests and responses
client = Lipdub.client
# Add logging middleware to your HTTP client if needed
```

### Getting Help

- **Documentation**: Check this README and inline code documentation
- **API Status**: Monitor [Lipdub API status page](https://status.lipdub.ai) for service issues
- **Support**: Contact support@lipdub.ai for API-related issues
- **Issues**: Report bugs on [GitHub Issues](https://github.com/upriser/lipdub-ruby/issues)

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

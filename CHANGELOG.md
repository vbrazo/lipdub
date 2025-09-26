# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- GitHub Actions CI workflow for automated testing
- Security audit with bundler-audit gem
- Support for Ruby 2.7, 3.0, 3.1, 3.2, and 3.3 in CI
- Project listing functionality (`GET /v1/projects`)
- Shot actors endpoint (`GET /v1/shots/{shot_id}/actors`)
- Shot translation endpoint (`POST /v1/shots/{shot_id}/translate`)
- Multi-actor generation endpoint (`POST /v1/shots/{shot_id}/generate-multi-actor`)
- Enhanced shot generation with new parameters (start_frame, loop_video, full_resolution, callback_url, timecode_ranges)
- Selective lip-dubbing functionality with timecode range validation and helper methods
- Comprehensive timecode handling (numeric seconds and SMPTE format)
- Frame buffer utility for seamless selective lip-dubbing transitions

### Fixed
- RSpec test compatibility issues with WebMock
- JSON parsing in all upload_complete methods
- File stubbing in test suite for better isolation
- Content-Type headers in all WebMock stubs

### Changed
- Enhanced documentation with CI and security audit information
- Updated contributing guidelines to include security audit step
- Added comprehensive selective lip-dubbing workflow examples and best practices
- Expanded README with detailed timecode usage examples

## [0.1.0] - 2025-09-26

### Added
- Initial release of the Lipdub Ruby client
- Video upload functionality with complete workflow support
- Audio upload functionality with validation
- Shot generation and monitoring capabilities  
- File download functionality
- Comprehensive error handling with custom exceptions
- Full test coverage with RSpec
- Complete documentation and usage examples
- Support for multiple video formats (MP4, MOV, AVI, WebM, MKV)
- Support for multiple audio formats (MP3, WAV, MP4/M4A)
- Configurable timeouts and base URL
- Automatic content type detection
- Status monitoring and polling capabilities

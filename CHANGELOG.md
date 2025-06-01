# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.1] - 2025-06-01

### Fixed
- Fixed paste functionality from menubar not working at cursor location
- Resolved issue where clipboard items wouldn't paste to the target application
- Fixed popover closure timing that was interfering with paste operations
- Fixed weak reference issue that could cause appDelegate to become nil

### Added
- Comprehensive logging throughout paste process for better debugging
- Multiple paste methods with intelligent fallback:
  - Direct text insertion using Accessibility API (primary method)
  - AppleScript keyboard simulation (secondary method)
  - CGEvent keyboard simulation (fallback method)
- Automatic accessibility permission checks and prompts
- Target application tracking before popover display

### Changed
- Improved application activation sequence with proper delays
- Enhanced popover management using delegate pattern
- Better error handling for paste operations

## [1.0.0] - 2024-05-30

### Added
- Initial release
- Clipboard history monitoring for text and images
- Customizable global hotkey (default: Ctrl+Shift+V)
- Menu bar integration
- Search functionality
- Keyboard navigation (1-9 keys for quick paste)
- Password protection with automatic masking
- Smart password detection
- Configurable excluded applications
- Source application tracking
- Settings window with hotkey customization
- Privacy settings for password masking
- Maximum 50 items history storage
- Right-click context menu
- Clear history functionality
- MIT License
- GitHub Actions CI/CD pipeline
- Contributing guidelines
- Comprehensive test suite

### Security
- Automatic masking of content from password managers
- Smart detection of password-like strings
- Local-only storage (no external data transmission)
- Secure paste functionality preserves actual passwords

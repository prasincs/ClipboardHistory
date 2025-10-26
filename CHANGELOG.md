# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Run Swift tests on Linux in CI using the official Swift container image to cover cross-platform code paths
- Rust-based Wayland daemon (`clipboard-history-linux`) that records clipboard history and surfaces an Omarchy/Hyprland selector via wofi
- Sticky multi-paste selector mode on Linux (`select --sticky`) with CLI parsing tests

### Changed
- Replaced external HotKey dependency with a vendored implementation to enable offline builds

## [v1.0.12] - 2025-06-05

### Security
- **Supply Chain Hardening**: Comprehensive protection against dependency attacks
  - Pin dependencies to exact versions instead of version ranges
  - Add cryptographic checksum verification for all dependencies
  - Implement automated dependency vulnerability scanning
- **CI/CD Security**: Multi-layer security validation pipeline
  - Secret detection with Gitleaks to prevent credential leaks
  - Dependency review for all pull requests
  - Mandatory security checks before any builds or releases
- **Development Security**: Security-first development workflow
  - Pre-commit hooks with security validation
  - Security checklist for contributors
  - Automated security scanning on every commit

### Added
- **Security Policy**: Complete SECURITY.md with vulnerability reporting process
- **Dependency Verification**: `scripts/verify-dependencies.sh` for checksum validation
- **Security Tools**: Gitleaks configuration and Dependabot setup
- **Make Targets**: `make security` and `make verify-deps` commands
- **Documentation**: Comprehensive security information in README

### Changed
- **Release Process**: Security checks now required before creating releases
- **Git Hooks**: Pre-commit hooks include security validation
- **CI Workflow**: Security job must pass before other CI jobs run
- **Package Management**: HotKey dependency pinned to exact version 0.2.1

## [v1.0.9] - 2025-06-05

### Fixed
- Fixed distance-based versioning to correctly add commit count instead of incrementing by 1

### Added
- Added `--push` option to release script for automatic tag pushing
- Added duplicate tag prevention with helpful error messages

## [1.0.5] - 2025-06-05

### Fixed
- Fixed empty window appearing on launch for menu bar app
- Fixed URLs being incorrectly identified as passwords and masked in clipboard history

### Added
- First-time user onboarding with welcome message explaining:
  - App runs in menu bar
  - Keyboard shortcut to show clipboard history
  - How to access settings via right-click
- Debug option to reset first launch flag (debug builds only)

## [1.0.4] - 2025-06-04

### Added
- Configurable app-specific paste behaviors
- Google Docs link paste support (automatically converts URLs to links with Cmd+K)
- Settings UI for configuring paste behaviors per application
- URL pattern matching for context-aware paste behaviors
- Automatic text selection before link creation in Google Docs

### Changed
- Only applies Google Docs link behavior when clipboard contains URLs (http:// or https://)
- Improved text selection to only select pasted content instead of entire document

## [1.0.3] - 2025-06-01

### Changed
- Modified release script to only create tags without pushing (CI handles releases)

## [1.0.2] - 2025-06-01

### Added
- Changelog file with historical release notes
- Distance-based release script for automated versioning

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

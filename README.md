# Clipboard History for macOS

[![CI](https://github.com/prasincs/ClipboardHistory/actions/workflows/ci.yml/badge.svg)](https://github.com/prasincs/ClipboardHistory/actions/workflows/ci.yml)
[![Swift Version](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2013.0+-blue.svg)](https://www.apple.com/macos)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A simple, secure, and customizable clipboard history manager for macOS with automatic password protection.

## What's New (v1.0.9)

- **Smart Google Docs Integration**: Automatically convert URLs to clickable links when pasting in Google Docs
- **App-Specific Paste Behaviors**: Configure custom paste actions for different applications
- **Improved URL Handling**: URLs are no longer mistakenly identified as passwords
- **Better First Launch Experience**: Clean menu bar app with helpful onboarding
- **Enhanced Release Process**: Automated versioning with required changelog updates

See [CHANGELOG.md](CHANGELOG.md) for full release history.

## Features

### Core Features
- **Clipboard Monitoring**: Automatically captures text and images copied to clipboard
- **History Storage**: Stores up to 50 recent clipboard items
- **Menu Bar App**: Runs discreetly in your menu bar without cluttering the dock
- **First Launch Onboarding**: Welcome message on first run explaining how to use the app

### Accessibility & Navigation
- **Customizable Hotkey**: Default is Ctrl+Shift+V, fully customizable in Settings
- **Search**: Instantly search through clipboard history
- **Keyboard Navigation**: Press 1-9 to quickly paste items
- **Visual Feedback**: Items show preview text and source application

### Smart Paste Features
- **App-Specific Behaviors**: Configure custom paste behaviors for different applications
- **Google Docs Integration**: Automatically converts URLs to clickable links when pasting in Google Docs
- **Context-Aware**: Detects both application and current URL for intelligent paste behavior
- **Multiple Paste Methods**: Fallback strategies ensure paste works across all applications

### Privacy & Security
- **Password Protection**: Automatically masks content from password managers (1Password, Bitwarden, etc.)
- **Smart Password Detection**: Identifies password-like strings but excludes URLs
- **Privacy Settings**: Configure which apps should have their content masked
- **Secure Pasting**: Masked passwords are pasted with their actual values
- **Local Storage Only**: All data stays on your machine, no external connections

## Building from Source

### Prerequisites
- macOS 13.0 or later
- Xcode Command Line Tools
- Swift 5.9 or later

### Build Instructions

1. Clone or download this repository
2. Navigate to the project directory
3. Build the app:
   ```bash
   make release
   ```

For other build options:
```bash
make help        # Show all available commands
make build       # Debug build
make test        # Run tests
make clean       # Clean build artifacts
```

## Installation

After building:
1. Move `ClipboardHistory.app` to your Applications folder
2. Double-click to launch
3. Grant accessibility permissions when prompted (required for global hotkey)
4. The app will appear in your menu bar

## Quick Start

1. **Look for the clipboard icon** in your menu bar (top-right of screen)
2. **Copy something** - The app automatically captures it
3. **Press Ctrl+Shift+V** to see your clipboard history
4. **Click any item** or press its number (1-9) to paste it
5. **Right-click the menu bar icon** for settings and options

That's it! The app runs quietly in the background, keeping your clipboard history safe and accessible.

## Usage

- **Ctrl+Shift+V** (or custom hotkey): Show clipboard history popup
- **Left-click menu bar icon**: Show/hide clipboard history
- **Right-click menu bar icon**: Show menu with Settings and Quit options
- **Number keys (1-9)**: Quickly paste items 1-9 from history
- **Enter**: Paste the first/selected item
- **Search**: Type to filter clipboard history
- **Click any item**: Paste that item

## Settings

Access Settings by right-clicking the menu bar icon and selecting "Settings..."

### Keyboard Shortcut
- Click the recorder field and press your desired key combination
- The app will show the current shortcut (e.g., ⌃⇧V)

### Privacy & Security
- **Mask Passwords**: Toggle automatic password masking on/off
- **Excluded Applications**: Manage apps whose content will be masked
  - Default includes: 1Password, Bitwarden, LastPass, Dashlane, Keeper, KeePassXC, Enpass
  - Add custom apps by typing the app name

### App-Specific Paste Behaviors
- Configure special paste behaviors for specific applications
- **Google Docs Link Paste**: Automatically converts URLs to clickable links
  - Only applies when pasting URLs (http:// or https://)
  - Works with Chrome, Safari, Firefox, Edge, and Arc
  - Can require specific URL patterns (e.g., docs.google.com)

### Clipboard History
- View current storage limit (50 items)
- **Clear History**: Remove all items from clipboard history

### About
- View app version and information
- Quick access to app description

## Privacy Features

- **Password Masking**: Content from password managers is automatically masked as "••••••••"
- **Smart Detection**: Automatically detects password-like strings (mixed case, numbers, special characters)
- **Source App Display**: Shows which app the content was copied from
- **Secure Pasting**: Masked passwords are pasted with their actual values, not the masked version

## Permissions

This app requires:
- **Accessibility Access**: For global hotkey support and simulating paste events

Grant these permissions in System Preferences > Security & Privacy > Privacy.

## Troubleshooting

### Common Issues

1. **Hotkey not working**
   - Ensure accessibility permissions are granted in System Settings > Privacy & Security > Accessibility
   - Try setting a different hotkey combination in Settings
   - Restart the app after granting permissions

2. **App not launching**
   - Check System Settings > Privacy & Security and allow the app
   - If you see "damaged" warning, right-click the app and select Open
   - Build from source if downloaded version doesn't work

3. **No clipboard history**
   - Start copying items - the app captures them automatically
   - Check if the source app is in the excluded list (Settings > Privacy)
   - Ensure the app is running (look for icon in menu bar)

4. **Paste not working**
   - Grant accessibility permissions if prompted
   - Try the fallback paste methods (app tries multiple approaches)
   - Make sure the target app is active before pasting

5. **Google Docs link paste not working**
   - Ensure you're pasting a URL (starts with http:// or https://)
   - Verify you're on docs.google.com
   - Check app-specific behaviors in Settings

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Quick Start for Contributors

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Building from Source

See the [Development](#building-from-source) section above for build instructions.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [HotKey](https://github.com/soffes/HotKey) - For global hotkey support
- The Swift community for excellent tools and libraries

## Security

This app takes security seriously with comprehensive supply chain protection:

### Data Security
- **No Network Access**: App doesn't connect to external services
- **Local Storage Only**: All clipboard data stays on your machine
- **Password Protection**: Content from password managers is automatically masked
- **Memory Safety**: Swift's memory safety prevents common vulnerabilities

### Supply Chain Security
- **Dependency Pinning**: All dependencies pinned to exact versions
- **Checksum Verification**: Dependencies verified with cryptographic checksums
- **Minimal Dependencies**: Only one external dependency (HotKey)
- **Automated Scanning**: CI/CD includes security scanning and secret detection
- **Regular Audits**: Dependencies regularly reviewed and updated

### Build Security
- **Reproducible Builds**: Deterministic build process
- **Security Checks**: Required security validation before releases
- **Code Review**: All changes require review before merging
- **Static Analysis**: SwiftLint checks for common security issues

See [SECURITY.md](SECURITY.md) for our complete security policy and vulnerability reporting process.

## Support

- **Issues**: Please report bugs and request features via [GitHub Issues](https://github.com/prasincs/ClipboardHistory/issues)
- **Discussions**: Join the conversation in [GitHub Discussions](https://github.com/prasincs/ClipboardHistory/discussions)

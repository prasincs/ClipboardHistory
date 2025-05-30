# Clipboard History for macOS

[![CI](https://github.com/prasincs/ClipboardHistory/actions/workflows/ci.yml/badge.svg)](https://github.com/prasincs/ClipboardHistory/actions/workflows/ci.yml)
[![Swift Version](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2013.0+-blue.svg)](https://www.apple.com/macos)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A simple, secure, and customizable clipboard history manager for macOS with automatic password protection.

## Features

- **Clipboard Monitoring**: Automatically captures text and images copied to clipboard
- **History Storage**: Stores up to 50 recent clipboard items
- **Customizable Hotkey**: Default is Ctrl+Shift+V, but can be changed in Settings
- **Search**: Search through clipboard history
- **Keyboard Navigation**: Use number keys (1-9) to quickly paste items
- **Menu Bar Icon**: Access clipboard history from the menu bar
- **Password Protection**: Automatically masks content from password managers
- **Privacy Settings**: Configure which apps should have their content masked
- **Smart Password Detection**: Automatically detects and masks likely passwords

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

## Usage

- **Ctrl+Shift+V** (or custom hotkey): Show clipboard history popup
- **Left-click menu bar icon**: Show/hide clipboard history
- **Right-click menu bar icon**: Show menu with Settings and Quit options
- **Number keys (1-9)**: Quickly paste items 1-9 from history
- **Enter**: Paste the first/selected item
- **Search**: Type to filter clipboard history
- **Click any item**: Paste that item

## Settings

Access Settings by right-clicking the menu bar icon and selecting "Settings..." or pressing Cmd+,

- **Keyboard Shortcut**: Click the recorder field and press your desired key combination
- **Privacy & Security**: 
  - Toggle password masking on/off
  - Manage list of excluded applications (content from these apps will be masked)
  - Default excluded apps include: 1Password, Bitwarden, LastPass, etc.
- **Clear History**: Remove all items from clipboard history
- **About**: View app version information

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

1. **Hotkey not working**: Make sure accessibility permissions are granted
2. **App not launching**: Check Security & Privacy settings and allow the app
3. **No clipboard history**: Start copying items - the app will capture them automatically

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

This app takes security seriously:
- Passwords from known password managers are automatically masked
- No data is sent to external servers
- All clipboard data stays local on your machine
- Open source for transparency

## Support

- **Issues**: Please report bugs and request features via [GitHub Issues](https://github.com/prasincs/ClipboardHistory/issues)
- **Discussions**: Join the conversation in [GitHub Discussions](https://github.com/prasincs/ClipboardHistory/discussions)

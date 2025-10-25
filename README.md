# Clipboard History for macOS

[![CI](https://github.com/prasincs/ClipboardHistory/actions/workflows/ci.yml/badge.svg)](https://github.com/prasincs/ClipboardHistory/actions/workflows/ci.yml)
[![Swift Version](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2013.0+-blue.svg)](https://www.apple.com/macos)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A simple, secure, and customizable clipboard history manager for macOS with automatic password protection. Includes a Rust-based Wayland daemon for Linux/Hyprland environments.

## What's New (v1.0.13)

- **🎯 Sticky Mode**: Revolutionary multi-paste workflow - press Space to keep popup open for rapid sequential pasting
- **⌨️ Enhanced Keyboard Navigation**: Full arrow key navigation with visual selection highlighting  
- **📌 Cursor-Based Popup**: Optional experimental feature to show clipboard history at cursor location
- **🚀 Direct Text Insertion**: Smart paste behavior that appends text without overwriting existing content
- **✨ Improved UX**: Better visual feedback, persistent popups, and keyboard-first design

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
- **Full Keyboard Navigation**: Arrow keys to navigate, Enter to paste, numbers 1-9 for quick selection
- **Sticky Mode**: Press Space to enable persistent popup for rapid multi-pasting workflow
- **Visual Selection**: Clear highlighting with blue borders shows current selection
- **Cursor-Based Popup**: Optional experimental feature to show popup at cursor location
- **Visual Feedback**: Items show preview text, source application, and paste status

### Smart Paste Features
- **App-Specific Behaviors**: Configure custom paste behaviors for different applications
- **Google Docs Integration**: Automatically converts URLs to clickable links when pasting in Google Docs
- **Context-Aware**: Detects both application and current URL for intelligent paste behavior
- **Direct Text Insertion**: In sticky mode, text is inserted without changing clipboard or overwriting content
- **Intelligent Appending**: Automatically positions cursor and adds spacing to prevent content overwriting
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

## Linux (Wayland/Hyprland) Frontend

The repository ships with a Rust-based daemon that brings clipboard history to Wayland compositors such as Hyprland.

### Requirements

- `wl-paste` and `wl-copy` from [wl-clipboard](https://github.com/bugaevc/wl-clipboard)
- [`wofi`](https://hg.sr.ht/~scoopta/wofi) (for the in-context selection menu)
- Rust 1.70 or later

### Build

```bash
cd linux
cargo build --release
```

The compiled binary is available at `linux/target/release/clipboard-history-linux`.

### Usage

1. Start the background daemon that records clipboard updates:
   ```bash
   ./linux/target/release/clipboard-history-linux daemon &
   ```
2. (Hyprland) Add a key binding to launch the selector (with optional sticky mode for rapid multi-paste workflows):
   ```ini
   bind=CTRL+SHIFT+V,exec,~/ClipboardHistory/linux/target/release/clipboard-history-linux select --sticky
   ```
   `--sticky` keeps the selector open after each paste so you can send several entries without re-triggering the shortcut. Omit the flag if you prefer the classic single-paste behavior.
3. Optionally inspect or clear history directly:
   ```bash
   ./linux/target/release/clipboard-history-linux print   # Masked list of entries
   ./linux/target/release/clipboard-history-linux clear   # Remove all stored entries
   ```

History is stored locally at `$XDG_DATA_HOME/clipboard-history/history.dat` (defaults to `~/.local/share/clipboard-history/`). Password-like entries are masked in the selector but remain available for pasting when chosen.

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

### Basic Navigation
- **Ctrl+Shift+V** (or custom hotkey): Show clipboard history popup
- **Left-click menu bar icon**: Show/hide clipboard history
- **Right-click menu bar icon**: Show menu with Settings and Quit options
- **↑/↓ Arrow keys**: Navigate through clipboard items
- **Enter**: Paste currently selected item
- **Number keys (1-9)**: Quickly paste items 1-9 from history
- **Escape**: Close popup
- **Search**: Type to filter clipboard history
- **Click any item**: Paste that item

### Sticky Mode (Multi-Paste Workflow)
- **Space**: Toggle sticky mode on/off (shows 📌 indicator when active)
- **In sticky mode**: Popup stays open after pasting for rapid sequential pasting
- **Example workflow**: 
  1. Press Ctrl+Shift+V → popup opens
  2. Press Space → sticky mode enabled
  3. Press 2 → pastes item 2, popup stays open
  4. Press 5 → pastes item 5, popup stays open
  5. ↓ arrow → navigate to item 3
  6. Enter → pastes item 3, popup stays open
  7. Space → disable sticky mode
  8. Escape → close popup

## Settings

Access Settings by right-clicking the menu bar icon and selecting "Settings..."

### Keyboard Shortcut
- Click the recorder field and press your desired key combination
- The app will show the current shortcut (e.g., ⌃⇧V)

### Privacy & Security
- **Mask Passwords**: Toggle automatic password masking on/off
- **Show clipboard at cursor (Experimental)**: Enable popup to appear at cursor location instead of menu bar
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

- [HotKey](https://github.com/soffes/HotKey) - Inspiration for the vendored global hotkey implementation
- The Swift community for excellent tools and libraries

## Security

This app takes security seriously with comprehensive supply chain protection:

### Data Security
- **No Network Access**: App doesn't connect to external services
- **Local Storage Only**: All clipboard data stays on your machine
- **Password Protection**: Content from password managers is automatically masked
- **Memory Safety**: Swift's memory safety prevents common vulnerabilities

### Supply Chain Security
- **Dependency Pinning**: All dependencies pinned to exact versions (none currently required)
- **Checksum Verification**: Dependencies verified with cryptographic checksums when present
- **Minimal Dependencies**: Zero third-party runtime dependencies
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

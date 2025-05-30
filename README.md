# Clipboard History for macOS

A simple macOS app that stores clipboard history and allows you to paste from history using Ctrl+Shift+V.

## Features

- **Clipboard Monitoring**: Automatically captures text and images copied to clipboard
- **History Storage**: Stores up to 50 recent clipboard items
- **Customizable Hotkey**: Default is Ctrl+Shift+V, but can be changed in Settings
- **Search**: Search through clipboard history
- **Keyboard Navigation**: Use number keys (1-9) to quickly paste items
- **Menu Bar Icon**: Access clipboard history from the menu bar
- **Settings**: Customize keyboard shortcuts and manage clipboard history

## Building from Source

### Prerequisites
- macOS 13.0 or later
- Xcode Command Line Tools
- Swift 5.9 or later

### Build Instructions

1. Clone or download this repository
2. Navigate to the project directory
3. Run the build script:
   ```bash
   ./build.sh
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
- **Clear History**: Remove all items from clipboard history
- **About**: View app version information

## Permissions

This app requires:
- **Accessibility Access**: For global hotkey support and simulating paste events

Grant these permissions in System Preferences > Security & Privacy > Privacy.

## Troubleshooting

1. **Hotkey not working**: Make sure accessibility permissions are granted
2. **App not launching**: Check Security & Privacy settings and allow the app
3. **No clipboard history**: Start copying items - the app will capture them automatically

## License

This is a sample project. Feel free to modify and use as needed.
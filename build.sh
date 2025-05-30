#!/bin/bash

echo "Building Clipboard History app..."

# Clean previous builds
rm -rf .build
rm -rf ClipboardHistory.app

# Build the executable
swift build -c release

# Create app bundle structure
mkdir -p ClipboardHistory.app/Contents/MacOS
mkdir -p ClipboardHistory.app/Contents/Resources

# Copy executable
cp .build/release/ClipboardHistory ClipboardHistory.app/Contents/MacOS/

# Copy Info.plist
cp Info.plist ClipboardHistory.app/Contents/

# Copy icon if it exists
if [ -f AppIcon.icns ]; then
    cp AppIcon.icns ClipboardHistory.app/Contents/Resources/
    echo "Copied app icon"
else
    echo "Warning: AppIcon.icns not found. Run create_icon_simple.py to generate it."
fi

# Copy assets if they exist
if [ -d Assets.xcassets ]; then
    cp -R Assets.xcassets ClipboardHistory.app/Contents/Resources/
    echo "Copied assets"
fi

echo "Build complete! The app is at ClipboardHistory.app"
echo ""
echo "To run the app:"
echo "  1. Double-click ClipboardHistory.app"
echo "  2. Grant accessibility permissions when prompted"
echo "  3. Use Ctrl+Shift+V to show clipboard history"
echo ""
echo "Note: You may need to allow the app in System Preferences > Security & Privacy"
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

# Create a simple icon (you can replace this with a proper icon later)
echo '<?xml version="1.0" encoding="UTF-8"?>
<svg width="512" height="512" viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg">
  <rect width="512" height="512" fill="#007AFF"/>
  <rect x="128" y="64" width="256" height="384" fill="white" rx="16"/>
  <rect x="160" y="128" width="192" height="32" fill="#007AFF"/>
  <rect x="160" y="192" width="192" height="32" fill="#007AFF"/>
  <rect x="160" y="256" width="192" height="32" fill="#007AFF"/>
</svg>' > ClipboardHistory.app/Contents/Resources/AppIcon.svg

echo "Build complete! The app is at ClipboardHistory.app"
echo ""
echo "To run the app:"
echo "  1. Double-click ClipboardHistory.app"
echo "  2. Grant accessibility permissions when prompted"
echo "  3. Use Ctrl+Shift+V to show clipboard history"
echo ""
echo "Note: You may need to allow the app in System Preferences > Security & Privacy"
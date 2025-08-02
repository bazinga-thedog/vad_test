#!/bin/bash

# iOS Build Script for Winamp Flutter App
# This script should be run on macOS with Xcode installed

echo "Building iOS app for Winamp..."

# Clean the project
flutter clean

# Get dependencies
flutter pub get

# Build for iOS (requires macOS with Xcode)
echo "Building iOS release..."
flutter build ios --release

echo "iOS build completed!"
echo "You can find the built app in: build/ios/iphoneos/Runner.app"
echo ""
echo "To build for iOS Simulator:"
echo "flutter build ios --simulator --release"
echo ""
echo "To build for specific device:"
echo "flutter build ios --release --flavor production" 
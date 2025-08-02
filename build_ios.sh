#!/bin/bash

# iOS Release Build Script
# This script builds the Flutter app for iOS in release mode
# Note: This must be run on macOS with Xcode installed

echo "Building Flutter app for iOS in release mode..."

# Clean the project
flutter clean

# Get dependencies
flutter pub get

# Build for iOS in release mode
flutter build ios --release --no-codesign

echo "iOS release build completed!"
echo "To build with code signing, use: flutter build ios --release"
echo "To archive for App Store, use Xcode to archive the project" 
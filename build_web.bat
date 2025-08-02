@echo off
REM Web Release Build Script for Windows
REM This script builds the Flutter app for web in release mode

echo Building Flutter app for web in release mode...

REM Clean the project
flutter clean

REM Get dependencies
flutter pub get

REM Build for web in release mode
flutter build web --release

echo Web release build completed!
echo Web files location: build\web\
echo To serve the web app: flutter run -d web-server --release
pause 
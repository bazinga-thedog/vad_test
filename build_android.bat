@echo off
REM Android Release Build Script for Windows
REM This script builds the Flutter app for Android in release mode

echo Building Flutter app for Android in release mode...

REM Clean the project
flutter clean

REM Get dependencies
flutter pub get

REM Build for Android in release mode
flutter build apk --release

echo Android release build completed!
echo APK file location: build\app\outputs\flutter-apk\app-release.apk
pause 
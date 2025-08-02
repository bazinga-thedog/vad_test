# Hello World Flutter App

A simple Flutter application that displays "Hello, World!" and includes a counter button.

## Features

- Clean, modern Material Design 3 UI
- Counter functionality with floating action button
- Cross-platform support (iOS and Android)
- Responsive design

## Getting Started

### Prerequisites

- Flutter SDK (3.5.0 or higher)
- Dart SDK
- Android Studio / Xcode (for platform-specific development)

### Installation

1. Clone or download this project
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the app

### Building for Platforms

#### Android
```bash
flutter build apk
```

#### iOS
```bash
flutter build ios
```

## Project Structure

```
lib/
  main.dart          # Main application entry point
android/             # Android-specific configuration
ios/                 # iOS-specific configuration
pubspec.yaml         # Flutter dependencies and configuration
```

## Dependencies

- `flutter`: Flutter SDK
- `cupertino_icons`: iOS-style icons
- `flutter_lints`: Code analysis and linting rules 
@echo off
echo Building Android app for Winamp...

REM Clean the project
flutter clean

REM Get dependencies
flutter pub get

REM Build for Android Release
echo Building Android release...
flutter build apk --release

REM Build for Android Profile
echo Building Android profile...
flutter build apk --profile

echo.
echo Android builds completed!
echo Release APK: build\app\outputs\flutter-apk\app-release.apk
echo Profile APK: build\app\outputs\flutter-apk\app-profile.apk
echo.
echo To install on connected device:
echo flutter install --release
echo.
pause 
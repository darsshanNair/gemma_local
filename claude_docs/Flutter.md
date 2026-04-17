# Flutter Project Instructions

This document describes Flutter-specific commands and instructions for Claude Code projects.

## CLI Commands

### General commands

- Use `fvm` prefix for Flutter commands (e.g., `fvm flutter pub get`, `fvm flutter clean`)
- Switch Flutter SDK version being used for the project based on which Flutter SDK is defined in the `Flutter version` section in `Claude.md` using `fvm use <version>`

## Projects with configuration files (config.json)

### Running
- `fvm flutter pub get` – install dependencies
- `fvm flutter run lib/main.dart --dart-define-from-file=config.json` – run using token from local config.json

### Building
- `flutter build apk --dart-define-from-file=config.json` – build Android APK with token from config.json
- `flutter build ios --dart-define-from-file=config.json` – build iOS with token from config.json
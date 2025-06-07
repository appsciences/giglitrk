# giglitrk

A macOS time tracking application built with Flutter that helps you track time spent on different client work.

## Features

- 9 independent timers in a 3x3 grid layout
- Exclusive timer operation - only one timer can run at a time
- Global keyboard shortcuts:
  - `Ctrl+Alt+⌘+[1-9]` to toggle individual timers
  - `Ctrl+Alt+⌘+0` to stop all timers
- In-app keyboard shortcuts (when app is focused)
  - Number keys `1-9` to toggle timers
  - `0` to stop all timers
- System theme support (light/dark mode)
- Visual timer display showing hours:minutes:seconds
- Timer status indicators (Running/Stopped)

## Requirements

- macOS
- Standard macOS accessibility permissions for global keyboard shortcuts

## Development

This is a Flutter desktop application. To run it:

1. Ensure you have Flutter installed and configured for desktop development
2. Clone the repository
3. Run `flutter pub get` to install dependencies
4. Run `flutter run -d macos` to launch the app

## Dependencies

- `hotkey_manager`: For global keyboard shortcuts
- `flutter/services`: For in-app keyboard handling
- Material Design 3 widgets and theming

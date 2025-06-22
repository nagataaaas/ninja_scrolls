# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ninja Scrolls (ニンジャスクロールズ) is a Flutter application for reading Ninja Slayer content in Japanese. It features episode reading, wiki browsing, and customizable settings.

## Build and Development Commands

```bash
# Setup project (clean and get dependencies)
make setup

# Lint code (sort imports)
make lint

# Run in development
flutter run

# Run tests
flutter test

# Build for production
make build  # iOS on macOS, Android APK/AppBundle on others

# Profile with SkSL caching
make profile-sksl
```

## Architecture

The codebase follows clean architecture with these key layers:

- **lib/src/entities/** - Domain models (e.g., user_settings)
- **lib/src/gateway/** - Data access layer
  - `database/` - SQLite implementations for notes, read states, wiki, search history
  - Storage implementations for secure storage and shared preferences
- **lib/src/providers/** - State management using Provider pattern
  - ScaffoldProvider, EpisodeIndexProvider, ThemeProvider, UserSettingsProvider, WikiIndexProvider
- **lib/src/services/** - Business logic (e.g., content parsing)
- **lib/src/view/** - UI components organized by feature
- **lib/src/static/** - Constants, routes, assets

## Key Technologies

- **State Management**: Provider pattern
- **Navigation**: go_router with shell-based navigation
- **Database**: SQLite via sqflite
- **Japanese Text**: Custom BudouX implementation in `lib/budoux/`
- **Theming**: adaptive_theme with light/dark mode support

## Important Patterns

1. **Navigation Structure**: Uses HomeShellScaffold with three main branches (Reader, Wiki, Settings)
2. **Offline-first**: Heavy caching with cached_network_image and local SQLite storage
3. **Platform-aware UI**: Differentiates iOS/Android for native feel
4. **Custom Transitions**: Liquid and curtain transitions in `lib/src/transitions/`

## Testing Approach

Tests should be placed in `test/` directory. Run with `flutter test`.

## Platform-specific Notes

- **Android**: Configured for internet access, supports Twitter queries
- **iOS**: Allows arbitrary loads, supports Twitter URL schemes
- Both platforms use custom Japanese app names and red-themed splash screens (#8d2828)
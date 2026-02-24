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

## Screen Structure

### Shell Container

| Widget | File | Description |
|--------|------|-------------|
| HomeShellScaffold | `lib/src/view/scaffold/home_shell_scaffold.dart` | StatefulShellRoute with BottomNavigationBar (3 tabs), dynamic AppBar, optional end drawer |

### Reader Branch

| Route | Widget | File | Description |
|-------|--------|------|-------------|
| `/chapters` | ChapterSelectorView | `lib/src/view/chapter_selector/view.dart` | Chapter list with TRILOGY/AoM sections and glitch effects |
| `/chapters/readHistory` | ReadHistoryView | `lib/src/view/chapter_selector/read_history/view.dart` | Recently read episodes (max 30) grouped by chapter with progress bars |
| `/chapters/:chapterId/episodes` | EpisodeSelectorView | `lib/src/view/chapter_selector/episode_selector/view.dart` | Episode list within a chapter with progress tracking |
| `/chapters/:chapterId/episodes/:episodeId` | EpisodeReaderView | `lib/src/view/chapter_selector/episode_selector/episode_reader/view.dart` | Full episode reader with HTML rendering, progress saving, TOC drawer |
| `/searchEpisode` | EpisodeSearchView | `lib/src/view/episode_search/view.dart` | Episode search with katakana normalization and search history |

### Wiki Branch

| Route | Widget | File | Description |
|-------|--------|------|-------------|
| `/searchWiki` | SearchWikiView | `lib/src/view/search_wiki/view.dart` | Wiki page search with recent access tracking |
| `/searchWiki/read` | SearchWikiReadView | `lib/src/view/search_wiki/read/view.dart` | WebView-based wiki reader with navigation controls |

Query params: `wikiTitle`, `wikiEndpoint`

### Settings Branch

| Route | Widget | File | Description |
|-------|--------|------|-------------|
| `/setting` | SettingsView | `lib/src/view/settings/view.dart` | Main settings with theme/animation options, cache management, app info |
| `/setting/theme` | SettingsThemeView | `lib/src/view/settings/theme/view.dart` | Theme mode (system/light/dark) and theme variant selection |
| `/setting/richAnimation` | SettingsAnimationView | `lib/src/view/settings/animations/view.dart` | Rich animation toggle (system/enable/disable) |

## Features by Area

### Episode Reader
- **Progress saving**: Auto-saves every 1000ms via ReadStateGateway; marks "read" at >95% progress
- **Progress restoration**: Restores scroll position on re-open using saved index and progress
- **Zoom**: WidgetZoom on all images (PNG and SVG)
- **Share**: Episode title + season info + app download links via SharePlus
- **TOC drawer**: End drawer with section jump, share/refresh buttons, prev/next navigation, book purchase links
- **Content filtering**: Strips amazon links, audio links, N-Files markers, serialization notes
- **Paid content**: Shows remaining character count indicator for premium content

### Episode Search
- **Full-text search**: Katakana-normalized matching on episode titles (`.katakanaized!`)
- **Query normalization**: Removes `・` and `、` punctuation for fuzzy matching
- **Search history**: SQLite-backed with swipe-to-dismiss, auto-refresh on selection (max 30 entries)
- **Results display**: Grouped by chapter with read progress bars

### Wiki
- **WebView**: `webview_flutter` (mobile) / `webview_windows` (Windows), JS enabled
- **Search**: Katakana-normalized title search with fallback to wikiwiki.jp server-side search
- **Recent access**: Tracks and displays recently opened wiki pages
- **Bottom toolbar**: Back/Forward/Reload/Open in browser/Copy link

### Settings
- **Themes (8 total)**:
  - Light: Bright (ブライト), Milk (ミルク), Leaf (リーフ), Autumn (オータム)
  - Dark: Black (ブラック), Dusk (ダスク), Fuji (フジ), Cyber (サイバー)
- **Animation control**: Follow OS / Enable / Disable; gates glitch shaders and custom transitions
- **Cache management**: Individual deletion for episodes, read states, images, TOC index, wiki pages; shows sizes
- **App info**: Version display, developer Twitter link, copyright, privacy policy link

## Data Layer

### SQLite Database (DieHard.db)

| Table | File | Primary Key | Purpose |
|-------|------|-------------|---------|
| `notes` | `lib/src/gateway/database/note.dart` | `id` (TEXT) | Episode content cache (HTML, title, eyecatch, index items, purchase links) |
| `read_states` | `lib/src/gateway/database/read_state.dart` | `note_id` (TEXT, FK→notes) | Reading progress (0-1 scale stored as int×1000), completion state, section index |
| `episode_search_history` | `lib/src/gateway/database/episode_search_history.dart` | `created_at` (TEXT) | Search query history (max 30 entries, auto-pruned) |
| `wiki_pages` | `lib/src/gateway/database/wiki.dart` | `title` (TEXT) | Wiki page index (sanitized title, endpoint, last accessed timestamp) |

### Storage

| Type | File | Use Case |
|------|------|----------|
| SecureStorage | `lib/src/gateway/secure_storage.dart` | Platform-native encrypted storage (Keychain/Keystore) |
| SharedPreferencesStorage | `lib/src/gateway/shared_preferences_storage.dart` | User settings (theme, animations) via `UserSettings` entity |

### Network Gateways

| Gateway | File | Endpoint |
|---------|------|----------|
| Note API | `lib/src/gateway/note.dart` | `https://note.com/api/v3/notes/{id}` — cache-first with SQLite fallback |
| Wiki Scraper | `lib/src/gateway/wiki.dart` | `https://wikiwiki.jp/njslyr/` — scrapes page list, multi-tier cache (memory→DB→network) |

## Custom UI Components

### Transitions (`lib/src/transitions/`)
- **LiquidTransition**: Red dripping liquid effect using cubic Bezier paths and `DripProgression`; falls back to platform transitions when rich animations disabled
- **TopCurtainTransition**: Vertical slide-down curtain effect; same fallback behavior
- **PathAnimation**: Shared `CustomClipper<Path>` for liquid drip path generation

### Loading (`lib/src/view/components/loading_screen/`)
- **ThrowingShuriken**: Ninja arm throws spinning shuriken animation (arm slide-in → rotation loop → throw); uses `TweenSequence` with assets (`loading_arm.png`, `loading_shuriken.png`, `loading_thumb.png`)
- **CircularIndicator**: Fallback `CircularProgressIndicator.adaptive()` when rich animations disabled
- Factory: `createLoadingIndicatorOnSetting()` selects loader based on `getRichAnimationEnabled()`

### Glitch Effects
- **AnimatedGlitch.shader()**: GPU-accelerated fragment shader (`packages/animated_glitch/shader/glitch.frag`) applied to chapter headers; randomized speed (30-80)

### Platform-specific UI
- **Picker**: `CupertinoPicker` (iOS) / `SimpleDialog` with ListView (Android) — `lib/src/view/components/show_platform_picker_modal.dart`
- **Swipe-to-pop**: iOS-only horizontal swipe gesture — `lib/src/view/components/swipe_to_pop_container.dart`
- **Transitions fallback**: `CupertinoPageTransition` (iOS) / `FadeUpwardsPageTransitionsBuilder` (Android)

## Typography

### Google Fonts (bundled in `assets/google_fonts/`)

| Font | Usage | Location |
|------|-------|----------|
| NotoSansJP (Regular/Bold/SemiBold) | Default text theme for all app text | `lib/src/providers/theme_provider.dart` |
| RubikGlitch | "TRILOGY" / "AoM" section headers with glitch effect | `lib/src/view/chapter_selector/view.dart` |
| RampartOne | Chapter title display (1.4× size) | `lib/src/view/components/episode_selector/build_chapter.dart` |
| ReggaeOne | AppBar title | `lib/src/view/scaffold/home_shell_scaffold.dart` |

### Text Scale (via theme_provider)
- headlineLarge: 26px/w600, headlineMedium: 20px/w600, headlineSmall: 18px
- bodyLarge: 16px, bodyMedium: 14px, bodySmall: 12px
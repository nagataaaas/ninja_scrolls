# Ninja Scrolls API Reference

## Table of Contents
1. [Provider APIs](#provider-apis)
2. [Gateway APIs](#gateway-apis)
3. [Database APIs](#database-apis)
4. [Service APIs](#service-apis)
5. [View Components](#view-components)
6. [Utility Functions](#utility-functions)

## Provider APIs

### EpisodeIndexProvider

Located at: `lib/src/providers/episode_index_provider.dart`

#### Properties
- `chapters`: List<Chapter> - All chapters in the index
- `chapterMap`: Map<String, Chapter> - Chapter lookup by ID
- `noteIdWithChapterToIndex`: Map<String, int> - Episode index lookup

#### Methods
```dart
// Load episode index (cached after first load)
Future<void> loadIndex({bool forceRefresh = false})

// Refresh index from network
Future<void> refreshIndex()

// Find episode by note ID
EpisodeLink? findEpisodeByNoteId(String noteId)

// Get next/previous episodes
EpisodeLink? getNextEpisode(String noteId)
EpisodeLink? getPrevEpisode(String noteId)

// Get chapter containing episode
Chapter? getChapterByNoteId(String noteId)
```

### WikiIndexProvider

Located at: `lib/src/providers/wiki_index_provider.dart`

#### Properties
- `wikiPages`: List<WikiPage> - All wiki pages
- `recentWikiPages`: List<WikiPage> - Recently accessed pages (max 10)
- `isLoadingWikiPages`: bool - Loading state for wiki pages
- `isLoadingRecentWikiPages`: bool - Loading state for recent pages

#### Methods
```dart
// Initialize wiki index
Future<void> ensureInitialized()

// Force refresh from network
Future<void> forceRefresh()

// Search wiki pages
List<SearchResultWikiPage> searchWikiPages(String query)

// Update page access time
Future<void> touchPage(String title)

// Remove from recent pages
Future<void> removeRecentPage(String title)
```

### ThemeProvider

Located at: `lib/src/providers/theme_provider.dart`

#### Properties
- `lightThemes`: Map<String, ThemeData> - Available light themes
- `darkThemes`: Map<String, ThemeData> - Available dark themes

#### Theme Names
- Light: bright, milk, leaf, autumn
- Dark: black, dusk, fuji, cyber

#### Methods
```dart
// Get theme by name and brightness
ThemeData? getTheme(String name, Brightness brightness)

// Get Japanese display name
String getThemeDisplayName(String name)
```

### UserSettingsProvider

Located at: `lib/src/providers/user_settings_provider.dart`

#### Properties
- `settings`: UserSettings - Current user settings
- `isRichAnimationsEnabled`: bool - Animation preference

#### Methods
```dart
// Initialize settings
Future<void> ensureInitialized()

// Update theme settings
Future<void> setThemeType(String themeType)
Future<void> setLightThemeName(String name)
Future<void> setDarkThemeName(String name)

// Update animation settings
Future<void> setAnimationType(String type)
```

### ScaffoldProvider

Located at: `lib/src/providers/scaffold_provider.dart`

#### Properties
- `customEpisodeAppBar`: PreferredSizeWidget? - Custom app bar for episodes
- `customWikiAppBar`: PreferredSizeWidget? - Custom app bar for wiki
- `episodeTitle`: String? - Current episode title
- `wikiTitle`: String? - Current wiki page title
- `endDrawerWidget`: Widget? - End drawer content

#### Methods
```dart
// Update UI elements
void setCustomEpisodeAppBar(PreferredSizeWidget? appBar)
void setCustomWikiAppBar(PreferredSizeWidget? appBar)
void setEpisodeTitle(String? title)
void setWikiTitle(String? title)
void setEndDrawerWidget(Widget? widget)
```

## Gateway APIs

### Note Gateway

Located at: `lib/src/gateway/note.dart`

```dart
class NoteGateway {
  // Fetch note content
  Future<Note> fetchNoteBody(
    String noteId, {
    bool useCache = true,
    bool readNow = false,
  })
}
```

### Wiki Gateway

Located at: `lib/src/gateway/wiki.dart`

```dart
class WikiGateway {
  // Singleton instance
  static WikiGateway instance

  // Get all wiki pages
  Future<List<WikiPage>> getPages({
    bool useCache = true,
    bool useDatabase = true,
  })

  // Utility methods
  static List<String> splitTitle(String title)
  static String sanitizeForSearch(String title)
  static bool isContentTitle(String title)
}
```

## Database APIs

### Note Database Gateway

Located at: `lib/src/gateway/database/note.dart`

```dart
class NoteDataBaseGateway {
  // Check if note is cached
  Future<bool> isCached(String noteId)

  // Get cache timestamp
  Future<DateTime?> cachedAt(String noteId)

  // Save note to database
  Future<void> save(Note note)

  // Load note from database
  Future<Note?> load(String noteId)

  // Get recently read notes
  Future<List<Note>> recentRead(int count)

  // Delete operations
  Future<void> delete(String noteId)
  Future<void> deleteAll()

  // Reset recent read timestamps
  Future<void> resetRecentReadAt()

  // Get table size
  Future<String> get pgSize
}
```

### Read State Gateway

Located at: `lib/src/gateway/database/read_state.dart`

```dart
class ReadStateGateway {
  // Get read status for multiple notes
  Future<Map<String, ReadStatus>> getStatus(List<String> noteIds)

  // Update read status
  Future<void> updateStatus(
    String noteId,
    ReadState state,
    double readProgress,
    int index,
  )

  // Clear all read states
  Future<void> deleteAll()
}

// Enums
enum ReadState { notRead, reading, read }
```

### Episode Search History Gateway

Located at: `lib/src/gateway/database/episode_search_history.dart`

```dart
class EpisodeSearchHistoryGateway {
  // Get all search history
  Future<List<InputHistoryData>> get all

  // Add or update search term
  Future<void> addOrTouch(InputHistoryData data)

  // Remove search term
  Future<void> remove(InputHistoryData data)
}
```

### Wiki Database Gateway

Located at: `lib/src/gateway/database/wiki.dart`

```dart
class WikiDataBaseGateway {
  // Check if wiki is cached
  Future<bool> get isCached

  // Get all wiki pages
  Future<List<WikiPage>> get all

  // Save wiki pages
  Future<void> save(List<WikiPage> pages)

  // Get recently accessed pages
  Future<List<WikiPage>> recentAccessed(int limit)

  // Update access time
  Future<void> updateLastAccessedAt(String title)

  // Remove from recent
  Future<void> removeAccessedAt(String title)

  // Get latest cache time
  Future<DateTime?> get latestCreatedAt
}
```

## Service APIs

### Chapter Parser

Located at: `lib/src/services/parser/parse_chapters.dart`

```dart
class ParseChapters {
  // Parse HTML into structured index
  static Future<Index> parse(String html)
}
```

## View Components

### Episode Reader

Located at: `lib/src/view/chapter_selector/episode_selector/episode_reader/view.dart`

#### Properties
- Displays episode content with progress tracking
- Supports image zooming
- Table of contents navigation
- Previous/next episode navigation

#### Route Parameters
```dart
EpisodeReaderPage({
  required String noteId,
  bool? showPrevButton,
  bool? showNextButton,
})
```

### Episode Search

Located at: `lib/src/view/episode_search/view.dart`

#### Features
- Real-time search with history
- Grouped results by chapter
- Swipe-to-delete history items
- Progress indicators on results

### Wiki Search

Located at: `lib/src/view/search_wiki/view.dart`

#### Features
- Search wiki pages
- Recently accessed pages
- Auto-focus search field
- External wiki search fallback

### Settings

Located at: `lib/src/view/settings/view.dart`

#### Sections
- Theme Settings
- Animation Settings
- App Information
- Privacy Policy Link

## Utility Functions

### Route Utilities

Located at: `lib/src/static/routes.dart`

```dart
class AppRoutes {
  // Route constants
  static const chapters = '/chapters';
  static const episodes = '/chapters/episodes';
  static const read = '/chapters/episodes/read';
  // ... more routes

  // Get Japanese title for route
  static String getRouteTitle(String routeName)

  // Convert path to route name
  static String toName(String route)
}
```

### Extension Methods

Located at: `lib/extentions.dart`

```dart
extension StringExtension on String {
  // Various string manipulation methods
}

extension ListExtension<T> on List<T> {
  // List utility methods
}
```

### Data Models

#### Note Model
```dart
class Note {
  final String id;
  final String title;
  final String html;
  final String? eyecatchUrl;
  final int? remainedCharNum;
  final List<IndexItem> indexItems;
  final bool isLimited;
  final bool isPurchased;
  final BookPurchaseLink? bookPurchaseLink;
  final DateTime? cachedAt;
  final DateTime? recentReadAt;
}
```

#### Chapter Model
```dart
class Chapter {
  final String id;
  final String title;
  final String subTitle;
  final int episodeCount;
  final List<ChapterChild> children;
  final String? encodedChildren; // For caching
}
```

#### WikiPage Model
```dart
class WikiPage {
  final String title;
  final String sanitizedTitle;
  final String endpoint;
  final DateTime? lastAccessedAt;
  
  String get url => '${WikiGateway.baseUrl}$endpoint';
}
```

#### UserSettings Model
```dart
class UserSettings {
  final String themeType; // 'light', 'dark', 'system'
  final String lightThemeName;
  final String darkThemeName;
  final String animationType; // 'on', 'off', 'system'
}
```

## Error Handling

Most APIs use standard Flutter error handling patterns:
- Network errors throw exceptions
- Database errors are logged and may return null
- UI components show error states or fallback content

## Performance Considerations

1. **Lazy Loading**: All providers load data on-demand
2. **Caching**: Aggressive caching at multiple layers
3. **Batch Operations**: Database operations are batched when possible
4. **Memory Management**: Automatic cleanup of old cached data

## Usage Examples

### Loading Episode Content
```dart
final episodeProvider = context.read<EpisodeIndexProvider>();
await episodeProvider.loadIndex();

final episode = episodeProvider.findEpisodeByNoteId('12345');
if (episode != null) {
  // Navigate to episode
}
```

### Searching Wiki
```dart
final wikiProvider = context.read<WikiIndexProvider>();
final results = wikiProvider.searchWikiPages('忍殺');

for (final result in results) {
  print('${result.page.title}: ${result.matchRate}');
}
```

### Updating Theme
```dart
final settingsProvider = context.read<UserSettingsProvider>();
await settingsProvider.setThemeType('dark');
await settingsProvider.setDarkThemeName('cyber');
```
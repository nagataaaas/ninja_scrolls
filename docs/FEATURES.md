# Ninja Scrolls (ニンジャスクロールズ) - Feature Documentation

## Table of Contents
1. [Overview](#overview)
2. [Core Features](#core-features)
3. [Architecture Overview](#architecture-overview)
4. [Detailed Feature Breakdown](#detailed-feature-breakdown)
5. [Technical Implementation Details](#technical-implementation-details)
6. [Data Management](#data-management)
7. [User Interface & Experience](#user-interface--experience)

## Overview

Ninja Scrolls is a Flutter-based mobile application designed for reading Ninja Slayer content in Japanese. The app provides a rich, offline-capable reading experience with wiki browsing, customizable themes, and comprehensive progress tracking.

### Key Characteristics
- **Target Platform**: iOS and Android
- **Primary Language**: Japanese
- **Content Source**: note.com API and wikiwiki.jp
- **Architecture**: Clean Architecture with Provider state management
- **Design Philosophy**: Offline-first with aggressive caching

## Core Features

### 1. Content Reading System
- **Episode Browser**: Hierarchical navigation through chapters and episodes
- **Reading View**: Immersive full-screen reading with customizable themes
- **Progress Tracking**: Automatic saving and restoration of reading position
- **Offline Reading**: All accessed content cached locally
- **Image Support**: Eye-catch images with zoom functionality
- **Table of Contents**: Quick navigation within long episodes

### 2. Wiki Integration
- **Wiki Browser**: Access to comprehensive Ninja Slayer wiki content
- **Search Functionality**: Japanese-optimized search with fuzzy matching
- **Recent Access**: Quick access to recently viewed wiki pages
- **Offline Caching**: Wiki index cached for offline browsing

### 3. Search & Discovery
- **Episode Search**: Full-text search across all episodes
- **Search History**: Auto-saved search terms with quick access
- **Smart Filtering**: Japanese text normalization for better results
- **Progress Indicators**: Visual progress bars on search results

### 4. Customization & Settings
- **Theme System**: 8 themes (4 light, 4 dark) with Japanese names
- **Animation Control**: Toggle rich animations for accessibility
- **Reading Preferences**: Customizable reading experience
- **System Integration**: Respects device accessibility settings

### 5. Navigation & UI
- **Bottom Navigation**: Three main sections (Reader, Wiki, Settings)
- **Gesture Support**: Swipe-to-go-back on iOS
- **Platform-Aware**: Native UI elements for iOS/Android
- **Custom Transitions**: Liquid and curtain transition effects

## Architecture Overview

```
lib/src/
├── entities/          # Domain models
├── gateway/           # Data access layer
│   ├── database/      # SQLite implementations
│   └── (network)      # API integrations
├── providers/         # State management
├── services/          # Business logic
├── static/            # Constants and assets
├── transitions/       # Custom animations
└── view/              # UI components
```

### Design Patterns
- **Repository Pattern**: Gateway layer abstracts data sources
- **Provider Pattern**: Reactive state management
- **Singleton Pattern**: Database and wiki gateway instances
- **Immutable State**: All state updates create new instances

## Detailed Feature Breakdown

### Content Management

#### Episode Structure
```
Index
├── TRILOGY (3 chapters)
│   ├── Chapter 1
│   │   ├── Episode Groups
│   │   └── Guides
│   └── ...
└── AoM (5+ seasons)
    ├── Season 1
    │   ├── Episode Groups
    │   └── Guides
    └── ...
```

#### Episode Features
- **Metadata**: Title, HTML content, eye-catch URL, purchase links
- **Progress States**: Not Read → Reading → Completed
- **Content Types**: Free, Limited (with character count), Purchased
- **Index Items**: Hierarchical table of contents for navigation

### Search System

#### Episode Search
- **Real-time Search**: Updates results as user types
- **History Management**: Last 30 searches saved
- **Grouping**: Results organized by chapter
- **Visual Feedback**: Progress bars and read status

#### Wiki Search
- **Binary Search**: Efficient lookup in sorted page list
- **Fuzzy Matching**: Handles variations in Japanese text
- **Score Calculation**: Relevance ranking based on match quality
- **Split Titles**: Handles compound titles (e.g., "A／B")

### Database Schema

#### Tables
1. **notes**: Episode content and metadata
2. **read_states**: Reading progress and status
3. **episode_search_history**: Search term history
4. **wiki_pages**: Wiki page index and access times

#### Key Relationships
- **Foreign Keys**: read_states → notes (CASCADE delete)
- **Indexes**: Optimized for lookup by ID and recent access

## Technical Implementation Details

### State Management

#### Providers
1. **EpisodeIndexProvider**
   - Manages episode hierarchy
   - Lazy loads and caches index
   - Provides navigation helpers (previous/next)

2. **WikiIndexProvider**
   - Maintains wiki page list
   - Implements search algorithms
   - Tracks recent access

3. **ThemeProvider**
   - Manages 8 theme variations
   - Integrates Material 3 design
   - Lazy loads Google Fonts

4. **UserSettingsProvider**
   - Persists user preferences
   - Platform-aware settings
   - Auto-saves on changes

5. **ScaffoldProvider**
   - Dynamic UI state management
   - Custom app bars
   - Navigation coordination

### Performance Optimizations

#### Caching Strategy
```
User Request
    ↓
Memory Cache → Database Cache → Network
    ↑               ↑              ↓
    └───────────────┴──────────────┘
```

#### Optimization Techniques
- **Lazy Loading**: All providers initialize on-demand
- **Binary Search**: O(log n) wiki page lookup
- **Batch Operations**: Bulk database inserts
- **Encoded Data**: Compressed chapter data storage
- **Limited History**: Auto-cleanup of old entries

### Japanese Text Handling

#### BudouX Integration
- **Custom Implementation**: Dart port of Google's BudouX
- **Line Breaking**: Natural Japanese text wrapping
- **Model-based**: Pre-trained ML model for segmentation

#### Text Processing
- **Sanitization**: Normalization for search
- **Katakana Conversion**: ひらがな → カタカナ
- **Case Handling**: Lowercase for Latin characters
- **Emoji Support**: Special rendering for episode markers

## Data Management

### Storage Layers

1. **Secure Storage**
   - Encryption for sensitive data
   - Platform-specific implementations

2. **SharedPreferences**
   - User settings persistence
   - Quick access preferences

3. **SQLite Database**
   - Content caching
   - Reading progress
   - Search history
   - Wiki index

4. **Memory Cache**
   - Active content
   - Computed indices
   - Search results

### Data Flow
```
API Request → Parse Response → Cache in Database → Update UI
                                      ↓
                              Memory Cache ← Provider State
```

## User Interface & Experience

### Visual Design

#### Theme System
- **Light Themes**: Bright, Milk, Leaf, Autumn
- **Dark Themes**: Black, Dusk, Fuji, Cyber
- **Material 3**: Modern design system
- **Custom Fonts**: Rubik Glitch, Reggae One, Noto Sans JP

#### Animation System
- **Liquid Transition**: Red dripping effect
- **Curtain Transition**: Top-sliding animation
- **Glitch Effects**: Animated headers
- **Platform Fallbacks**: Native transitions when disabled

### Navigation Structure
```
Home Shell
├── Reader (本)
│   ├── Chapter List
│   ├── Episode List
│   ├── Episode Reader
│   └── Read History
├── Wiki (検索)
│   ├── Wiki Search
│   └── Wiki Reader
└── Settings (設定)
    ├── Theme Settings
    ├── Animation Settings
    └── App Info
```

### Accessibility Features
- **Animation Toggle**: Respects system preferences
- **High Contrast**: Dark themes for readability
- **Large Touch Targets**: Easy navigation
- **Progress Indicators**: Clear visual feedback

### Platform-Specific Features

#### iOS
- **Swipe-to-go-back**: Native gesture support
- **Cupertino Transitions**: Platform-appropriate animations
- **Back Button**: iOS-style navigation

#### Android
- **Material Design**: Native Android UI patterns
- **Fade Transitions**: Standard Android animations
- **System Back**: Hardware button support

## Security & Privacy

### Data Protection
- **Local Storage Only**: No cloud sync
- **Secure Storage**: Encrypted sensitive data
- **No Analytics**: Privacy-focused design
- **No User Accounts**: Anonymous usage

### Network Security
- **HTTPS Only**: Secure content fetching
- **Certificate Pinning**: Not implemented (relies on OS)
- **API Keys**: No authentication required

## Performance Characteristics

### Startup Performance
- **Lazy Initialization**: ~100ms cold start
- **Cached Index**: Instant navigation
- **Async Loading**: Non-blocking UI

### Runtime Performance
- **60 FPS Scrolling**: Optimized lists
- **Instant Search**: Binary search algorithms
- **Memory Efficient**: Automatic cache cleanup
- **Battery Friendly**: Minimal background activity

## Future Enhancement Opportunities

1. **Cloud Sync**: Multi-device reading progress
2. **Bookmarks**: Save favorite passages
3. **Annotations**: Personal notes on episodes
4. **Export Options**: Save content for offline reading
5. **Social Features**: Share favorite episodes
6. **Advanced Search**: Full-text search with filters
7. **Reading Statistics**: Time spent, pages read
8. **Custom Themes**: User-created color schemes
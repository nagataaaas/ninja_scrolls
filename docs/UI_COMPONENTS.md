# Ninja Scrolls UI Components Guide

## Table of Contents
1. [Screen Components](#screen-components)
2. [Reusable Components](#reusable-components)
3. [Transitions & Animations](#transitions--animations)
4. [Platform-Specific Components](#platform-specific-components)
5. [Theme & Styling](#theme--styling)
6. [Component Hierarchy](#component-hierarchy)

## Screen Components

### Home Shell Scaffold
**Location**: `lib/src/view/scaffold/home_shell_scaffold.dart`

The main navigation container for the app with bottom navigation bar.

#### Features
- Three navigation branches: Reader, Wiki, Settings
- Dynamic app bar based on current route
- Custom action buttons per screen
- End drawer support for episode reader

#### Usage
```dart
HomeShellScaffold(
  navigationShell: shell, // StatefulNavigationShell from go_router
)
```

#### Navigation Items
- **本** (Books) - Episode reader section
- **検索** (Search) - Wiki search section  
- **設定** (Settings) - App settings

### Chapter Selector
**Location**: `lib/src/view/chapter_selector/view.dart`

Displays all available chapters organized by content type.

#### Visual Elements
- Glitch-style animated headers (when animations enabled)
- Ninja Slayer logo overlays
- Section dividers
- Pull-to-refresh functionality

#### Sections
- **TRILOGY**: First 3 chapters
- **AoM**: Additional seasons (4+)

### Episode Selector
**Location**: `lib/src/view/chapter_selector/episode_selector/view.dart`

Shows episodes within a selected chapter.

#### Components
- Chapter banner with title and episode count
- Episode groups with visual grouping
- Progress bars showing read status
- Guide sections with rounded backgrounds
- "Read from beginning" / "Continue reading" buttons

#### Episode Item Features
- Emoji display (2x headline size)
- Title and subtitle
- Progress indicator bar
- Clickable navigation

### Episode Reader
**Location**: `lib/src/view/chapter_selector/episode_selector/episode_reader/view.dart`

Full-screen reading experience for episode content.

#### Key Features
- Scrollable content with progress tracking
- Eye-catch header images
- Image zoom functionality
- Table of contents drawer
- Previous/Next navigation
- Auto-save reading position

#### Special Elements
- Progress indicator icon (left side)
- Purchase links with book covers
- Smooth scroll to sections
- Swipe-to-go-back (iOS only)

### Episode Search
**Location**: `lib/src/view/episode_search/view.dart`

Search interface for finding episodes.

#### Features
- Search bar in app bar
- Search history with quick access
- Real-time filtering
- Results grouped by chapter
- Swipe-to-delete history items

#### Search Result Display
- Chapter headers
- Episode items with progress
- Emoji support
- Visual hierarchy

### Wiki Search
**Location**: `lib/src/view/search_wiki/view.dart`

Wiki page browser and search.

#### Sections
- Recently accessed pages (max 10)
- All pages listing
- Search functionality
- External wiki search fallback

#### Design Elements
- Section headers with thick borders
- Reggae One font for headers
- Auto-focus search field
- Fixed item heights

### Read History
**Location**: `lib/src/view/chapter_selector/read_history/view.dart`

Shows recently read episodes.

#### Features
- Episodes grouped by chapter
- Progress indicators
- Up to 30 most recent items
- Empty state message
- Pull-to-refresh

### Settings Screen
**Location**: `lib/src/view/settings/view.dart`

App configuration and preferences.

#### Sections
1. **Theme Settings**
   - Light theme selection
   - Dark theme selection
   - Auto/manual theme switching

2. **Animation Settings**
   - Rich animations toggle
   - System preference respect

3. **App Information**
   - Version info
   - Privacy policy link
   - Copyright notice

## Reusable Components

### HTML Widget
**Location**: `lib/src/view/chapter_selector/episode_selector/episode_reader/components/htmlWidget.dart`

Renders episode HTML content with styling.

#### Features
- Custom CSS styling
- Font family configuration
- Link handling
- Image support

### Progress Indicator
**Location**: `lib/src/view/components/progress_indicator.dart`

Visual reading progress display.

#### Types
- Bar indicator (under episodes)
- Icon indicator (in reader)
- Percentage display

### Loading Screens
**Location**: `lib/src/view/components/loading_screen/`

#### Variants
1. **Circular Indicator**: Standard platform indicator
2. **Throwing Shuriken**: Custom animated loader

### Episode Selector Component
**Location**: `lib/src/view/components/episode_selector/build_chapter.dart`

Reusable chapter display component.

#### Features
- Banner image
- Title and subtitle
- Episode count
- Consistent styling

### Platform Modals
**Location**: `lib/src/view/components/`

#### Components
- **show_platform_confirm_alert.dart**: Confirmation dialogs
- **show_platform_picker_modal.dart**: Selection lists

### Swipe Container
**Location**: `lib/src/view/components/swipe_to_pop_container.dart`

iOS-style swipe-to-go-back gesture support.

## Transitions & Animations

### Liquid Transition
**Location**: `lib/src/transitions/liquid_transition.dart`

Creates a red liquid dripping effect during navigation.

#### Properties
- Duration: 800ms
- Color: Red (#FF0000)
- Disabled when animations are off
- Falls back to platform defaults

### Top Curtain Transition
**Location**: `lib/src/transitions/top_curtain_transition.dart`

Slides new page from top like a curtain.

#### Properties
- Smooth slide animation
- Respects animation settings
- Platform fallbacks

### Path Animation
**Location**: `lib/src/transitions/path_animation.dart`

Utility for creating path-based animations.

## Platform-Specific Components

### iOS Features
- Cupertino-style navigation
- Swipe-to-go-back gestures
- iOS back button in app bar
- Cupertino page transitions

### Android Features
- Material Design components
- Android-style settings list
- Fade upward transitions
- Hardware back button support

## Theme & Styling

### Color Schemes

#### Light Themes
1. **Bright (ブライト)**: Clean, high contrast
2. **Milk (ミルク)**: Soft, warm tones
3. **Leaf (リーフ)**: Nature-inspired greens
4. **Autumn (オータム)**: Warm autumn colors

#### Dark Themes
1. **Black (ブラック)**: Pure black OLED-friendly
2. **Dusk (ダスク)**: Twilight purple tones
3. **Fuji (フジ)**: Mount Fuji inspired
4. **Cyber (サイバー)**: Cyberpunk aesthetics

### Typography

#### Font Families
- **Noto Sans JP**: Main Japanese text
- **Rubik Glitch**: Glitch effect headers
- **Reggae One**: Section headers
- **System Default**: UI elements

#### Text Styles
- Headlines: Large, bold for sections
- Body: Readable size for content
- Captions: Small text for metadata

### Common Design Elements

#### Borders & Spacing
- Section borders: 6px colored left border
- Card padding: 16px standard
- List item spacing: 8px between items

#### Colors
- Primary: Red theme (#8d2828)
- Background: Varies by theme
- Text: High contrast with background
- Progress bars: Theme accent colors

## Component Hierarchy

```
HomeShellScaffold
├── AppBar (Dynamic)
│   ├── Title
│   ├── Back Button (iOS)
│   └── Action Buttons
├── Body (Navigation Shell)
│   ├── Chapter Selector
│   │   ├── Glitch Header
│   │   └── Chapter List
│   ├── Episode Selector
│   │   ├── Chapter Banner
│   │   ├── Action Buttons
│   │   └── Episode List
│   ├── Episode Reader
│   │   ├── Content View
│   │   ├── Progress Indicator
│   │   └── End Drawer
│   ├── Wiki Search
│   │   ├── Search Bar
│   │   ├── Recent Pages
│   │   └── All Pages
│   └── Settings
│       ├── Theme Section
│       ├── Animation Section
│       └── App Info
├── Bottom Navigation Bar
└── End Drawer (Episode Reader Only)
```

## Best Practices

### Component Design
1. Use Provider for state management
2. Implement platform-aware UI
3. Support theme variations
4. Include loading states
5. Handle empty states

### Performance
1. Use const constructors where possible
2. Implement lazy loading for lists
3. Cache computed values
4. Minimize rebuilds with selective consumers

### Accessibility
1. Support reduced motion preferences
2. Ensure sufficient color contrast
3. Provide meaningful semantics
4. Test with screen readers

### Japanese Text
1. Use BudouX for line breaking
2. Support vertical text where appropriate
3. Handle ruby text (furigana)
4. Ensure proper font support
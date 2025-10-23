# Scrib — SwiftUI Book Writing App

A modern, cross-platform book writing application for iOS 26 and macOS 26 that reimagines Apple Notes as a book-authoring environment.

## Overview

Scrib blends the minimalist design of Apple Notes with robust manuscript management tools from Scrivener, offering distraction-free writing, chapter organization, and seamless cross-device editing.

### Phase One Features (Current)

- **Three-Column Navigation**: Books (sidebar) → Chapters (middle) → Editor (detail)
- **Book Management**: Create, rename, duplicate, and delete books
- **Chapter Management**: Create, rename, reorder, duplicate, and delete chapters
- **Writing Environment**:
  - Full-screen text editor with auto-save
  - Real-time word and character count
  - Title editing inline
  - Clean, distraction-free interface
- **Local Persistence**: SwiftData-based storage with automatic saving
- **Cross-Platform**: Universal app for iOS and macOS
- **Apple Notes Aesthetic**: SF Pro Text, system colors, native UI patterns

## Project Structure

```
Scrib/
├── App/
│   └── ScribApp.swift              # Main app entry point
├── Models/
│   ├── Book.swift                  # Book data model
│   ├── Chapter.swift               # Chapter data model
│   └── DataStore.swift             # SwiftData persistence layer
├── Views/
│   ├── ContentView.swift           # Root navigation container
│   ├── BookListView.swift          # Sidebar: Books list
│   ├── ChapterListView.swift       # Middle: Chapters list
│   ├── ChapterEditorView.swift     # Detail: Chapter editor
│   └── SettingsView.swift          # App settings (macOS)
├── ViewModels/
│   ├── BookViewModel.swift         # Book CRUD operations
│   └── ChapterViewModel.swift      # Chapter operations & auto-save
├── Extensions/
│   ├── Date+Extensions.swift       # Date formatting utilities
│   └── Color+Extensions.swift      # Color theming utilities
└── Resources/
    └── Assets.xcassets             # App icons and assets

ScribTests/
├── BookModelTests.swift            # Unit tests for Book model
└── ChapterModelTests.swift         # Unit tests for Chapter model
```

## Technology Stack

- **Language**: Swift 6.1
- **Framework**: SwiftUI (2025)
- **Persistence**: SwiftData
- **Architecture**: MVVM (Model-View-ViewModel)
- **Platforms**: iOS 26+, macOS 26+
- **Testing**: Swift Testing framework

## Getting Started

### Prerequisites

- Xcode 16+ with Swift 6.1 support
- macOS 26 SDK
- iOS 26 SDK
- Apple Developer account (for device testing)

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/scrib.git
   cd scrib
   ```

2. Open the project in Xcode:
   ```bash
   open Scrib.xcodeproj
   ```

3. Select your target (iOS or macOS)

4. Build and run (⌘R)

### First Launch

On first launch, Scrib automatically creates sample data:
- One book: "My First Novel"
- Three chapters with sample content

You can delete this sample data and start fresh.

## Key Features

### Book Management

- **Create Books**: Tap the + button in the sidebar
- **Rename Books**: Right-click (macOS) or long-press (iOS) → Rename
- **Duplicate Books**: Context menu → Duplicate (copies all chapters)
- **Delete Books**: Swipe left or context menu → Delete

### Chapter Management

- **Create Chapters**: Tap + in the chapter list
- **Rename Chapters**: Context menu → Rename
- **Reorder Chapters**: Drag and drop (iOS: tap Edit first)
- **Duplicate Chapters**: Context menu → Duplicate
- **Delete Chapters**: Swipe left or context menu → Delete

### Writing

- **Auto-Save**: Changes save automatically after 1 second of inactivity
- **Manual Save**: Press ⌘S on macOS
- **Word Count**: Displayed in real-time in the status bar
- **Character Count**: Also displayed in the status bar
- **Title Editing**: Click the pencil icon next to the chapter title

### Keyboard Shortcuts (macOS)

- `⌘N`: New book (sidebar) or new chapter (chapter list)
- `⌘S`: Manual save
- `⌘W`: Close window
- `⌘Delete`: Delete selected item
- `⌘F`: Focus search

## Architecture

### Data Layer

**SwiftData Models**:
- `Book`: Top-level container with chapters array
- `Chapter`: Individual writing unit with content and metadata

**Relationships**:
- Book → Chapters (one-to-many, cascade delete)
- Chapter → Book (many-to-one, bidirectional)

### View Models

**BookViewModel**:
- Create, update, delete books
- Search and filter functionality
- Book duplication with chapters

**ChapterViewModel**:
- Create, update, delete chapters
- Auto-save with 1-second debouncing
- Chapter reordering and duplication

### Views

**Three-Column Layout**:
1. **Sidebar** (BookListView): All books
2. **Content** (ChapterListView): Chapters in selected book
3. **Detail** (ChapterEditorView): Editor for selected chapter

## Testing

### Running Tests

```bash
# Run all tests
⌘U in Xcode

# Or via command line
xcodebuild test -scheme Scrib -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Test Coverage

- Book model: Initialization, word counts, sorting
- Chapter model: Word counting, content updates, ordering
- View models: CRUD operations (planned)

## Performance

Phase One targets:
- **List Scrolling**: 120Hz on ProMotion devices
- **Chapter Load**: <100ms
- **Auto-Save Latency**: <50ms after debounce
- **Memory Usage**: <100MB for 50 books with 1000 chapters

## Future Roadmap

### Phase Two
- CloudKit sync across devices
- Export to EPUB, PDF, DOCX
- Search and filtering
- Tags and metadata

### Phase Three
- AI integration (Claude API)
- Revision history with diffs
- Collaboration features
- Analytics dashboard

### Phase Four
- App extensions (widgets, share sheet)
- Marketing tools
- Advanced formatting
- Focus mode

## Design Guidelines

Following Apple HIG 2025:
- **Typography**: SF Pro Text, 16pt default
- **Spacing**: Consistent with system standards
- **Colors**: System dynamic colors (light/dark mode)
- **Symbols**: SF Symbols throughout
- **Accessibility**: Full Dynamic Type support

## Contributing

This is currently a Phase One implementation. Contributions are welcome for:
- Bug fixes
- Performance improvements
- Test coverage
- Documentation

Please follow Swift API Design Guidelines and maintain the Apple Notes aesthetic.

## License

Copyright © 2025 Scrib. All rights reserved.

## Acknowledgments

- Inspired by Apple Notes and Scrivener
- Built with SwiftUI and SwiftData
- Follows Apple HIG 2025 standards

---

**Current Version**: 1.0.0 (Phase One)
**Last Updated**: January 2025
**Maintained By**: Scrib Development Team

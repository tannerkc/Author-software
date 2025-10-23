# Scrib - Phase One Implementation Plan

## Overview
Phase One establishes the foundational architecture and core functionality of Scrib. This phase delivers a working MVP that demonstrates the Books-and-Chapters hierarchy with basic editing capabilities, local persistence, and cross-platform navigation (iOS/macOS).

**Timeline Estimate:** 2-3 weeks
**Goal:** Functional prototype with core writing and organization features

---

## Phase One Scope

### IN SCOPE (MVP Features)
1. Project setup and structure
2. Core data models (Book, Chapter)
3. Three-column navigation (Books → Chapters → Editor)
4. Basic chapter creation, editing, and deletion
5. Local persistence using SwiftData
6. Word count display
7. Basic UI matching Apple Notes aesthetic
8. Cross-platform support (iOS/macOS)

### OUT OF SCOPE (Future Phases)
- CloudKit sync
- AI integration (Claude API)
- Export functionality (EPUB, PDF, DOCX)
- Collaboration and sharing
- Analytics dashboard
- Revision history
- App extensions (widgets, share sheet)
- Advanced features (focus mode, templates, tags)

---

## Implementation Tasks

### 1. Project Setup and Configuration

#### 1.1 Create Xcode Project
**Priority:** Critical
**Estimated Time:** 30 minutes

**Tasks:**
- Create new Xcode project: "Scrib"
- Set bundle identifier: `com.scrib.app`
- Configure multiplatform app (iOS 26 + macOS 26 targets)
- Set minimum deployment targets (iOS 26.0, macOS 26.0)
- Enable Swift 6.1 language mode
- Configure build settings for strict concurrency checking

**Deliverable:** Base Xcode project structure

---

#### 1.2 Project Structure
**Priority:** Critical
**Estimated Time:** 20 minutes

**Directory Layout:**
```
Scrib/
├── App/
│   ├── ScribApp.swift           # Main app entry point
│   └── AppConfig.swift          # App-wide configuration
├── Models/
│   ├── Book.swift               # Book data model
│   ├── Chapter.swift            # Chapter data model
│   └── DataStore.swift          # SwiftData persistence layer
├── Views/
│   ├── BookListView.swift       # Sidebar - Books list
│   ├── ChapterListView.swift    # Middle column - Chapters list
│   ├── ChapterEditorView.swift  # Detail - Chapter editor
│   └── ContentView.swift        # Root navigation container
├── ViewModels/
│   ├── BookViewModel.swift      # Book management logic
│   └── ChapterViewModel.swift   # Chapter management logic
├── Extensions/
│   └── Date+Extensions.swift    # Date formatting helpers
└── Resources/
    └── Assets.xcassets          # Colors, images, symbols
```

**Deliverable:** Organized folder structure with placeholder files

---

### 2. Data Layer Implementation

#### 2.1 Core Data Models
**Priority:** Critical
**Estimated Time:** 1 hour

**Book Model (`Models/Book.swift`):**
```swift
import Foundation
import SwiftData

@Model
final class Book {
    @Attribute(.unique) var id: UUID
    var title: String
    var genre: String
    var dateCreated: Date
    var lastModified: Date

    @Relationship(deleteRule: .cascade, inverse: \Chapter.book)
    var chapters: [Chapter]

    init(
        id: UUID = UUID(),
        title: String,
        genre: String = "General",
        dateCreated: Date = Date(),
        lastModified: Date = Date(),
        chapters: [Chapter] = []
    ) {
        self.id = id
        self.title = title
        self.genre = genre
        self.dateCreated = dateCreated
        self.lastModified = lastModified
        self.chapters = chapters
    }

    var sortedChapters: [Chapter] {
        chapters.sorted { $0.order < $1.order }
    }

    var totalWordCount: Int {
        chapters.reduce(0) { $0 + $1.wordCount }
    }
}
```

**Chapter Model (`Models/Chapter.swift`):**
```swift
import Foundation
import SwiftData

@Model
final class Chapter {
    @Attribute(.unique) var id: UUID
    var title: String
    var content: String
    var order: Int
    var dateCreated: Date
    var lastModified: Date

    var book: Book?

    init(
        id: UUID = UUID(),
        title: String,
        content: String = "",
        order: Int = 0,
        dateCreated: Date = Date(),
        lastModified: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.order = order
        self.dateCreated = dateCreated
        self.lastModified = lastModified
    }

    var wordCount: Int {
        let words = content.split { $0.isWhitespace || $0.isNewline }
        return words.count
    }

    var characterCount: Int {
        content.count
    }
}
```

**Key Features:**
- SwiftData `@Model` macro for persistence
- Cascade delete relationships
- Computed properties for word/character counts
- UUID-based unique identification
- Bidirectional Book-Chapter relationship

**Deliverable:** Fully implemented data models with SwiftData annotations

---

#### 2.2 SwiftData Container Setup
**Priority:** Critical
**Estimated Time:** 45 minutes

**App Configuration (`App/ScribApp.swift`):**
```swift
import SwiftUI
import SwiftData

@main
struct ScribApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Book.self, Chapter.self])
    }
}
```

**DataStore Helper (`Models/DataStore.swift`):**
```swift
import Foundation
import SwiftData

@MainActor
final class DataStore: ObservableObject {
    let modelContainer: ModelContainer
    let modelContext: ModelContext

    init() {
        let schema = Schema([Book.self, Chapter.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
            modelContext = modelContainer.mainContext
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    func createSampleData() {
        let book = Book(title: "My First Novel", genre: "Fiction")
        let chapter1 = Chapter(title: "Chapter 1", content: "It was a dark and stormy night...", order: 0)
        let chapter2 = Chapter(title: "Chapter 2", content: "", order: 1)

        book.chapters = [chapter1, chapter2]
        chapter1.book = book
        chapter2.book = book

        modelContext.insert(book)

        try? modelContext.save()
    }
}
```

**Features:**
- Centralized model container configuration
- Helper method for sample data generation
- Error handling for persistence failures

**Deliverable:** SwiftData persistence layer fully configured

---

### 3. View Models (MVVM Layer)

#### 3.1 BookViewModel
**Priority:** High
**Estimated Time:** 1 hour

**Location:** `ViewModels/BookViewModel.swift`

**Responsibilities:**
- Fetch all books from SwiftData
- Create new books
- Delete books
- Update book metadata
- Sort books by date

**Key Methods:**
```swift
- func createBook(title: String, genre: String) -> Book
- func deleteBook(_ book: Book)
- func updateBook(_ book: Book)
- func fetchBooks() -> [Book]
```

**Deliverable:** Complete BookViewModel with CRUD operations

---

#### 3.2 ChapterViewModel
**Priority:** High
**Estimated Time:** 1 hour

**Location:** `ViewModels/ChapterViewModel.swift`

**Responsibilities:**
- Create new chapters within a book
- Delete chapters
- Update chapter content and title
- Reorder chapters
- Auto-save on text change (debounced)

**Key Methods:**
```swift
- func createChapter(in book: Book, title: String) -> Chapter
- func deleteChapter(_ chapter: Chapter)
- func updateChapterContent(_ chapter: Chapter, content: String)
- func reorderChapters(in book: Book, from: IndexSet, to: Int)
- func autoSave(chapter: Chapter)
```

**Features:**
- Debounced auto-save (1-second delay)
- Automatic word count updates
- lastModified timestamp management

**Deliverable:** Complete ChapterViewModel with editing logic

---

### 4. User Interface Implementation

#### 4.1 Root Navigation Container
**Priority:** Critical
**Estimated Time:** 1.5 hours

**ContentView (`Views/ContentView.swift`):**
```swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.lastModified, order: .reverse) private var books: [Book]

    @State private var selectedBook: Book?
    @State private var selectedChapter: Chapter?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar: Books
            BookListView(books: books, selection: $selectedBook)
        } content: {
            // Middle: Chapters
            if let book = selectedBook {
                ChapterListView(book: book, selection: $selectedChapter)
            } else {
                Text("Select a book")
                    .foregroundStyle(.secondary)
            }
        } detail: {
            // Detail: Editor
            if let chapter = selectedChapter {
                ChapterEditorView(chapter: chapter)
            } else {
                Text("Select a chapter to begin writing")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}
```

**Features:**
- Three-column NavigationSplitView
- SwiftData @Query for automatic updates
- State management for selections
- Adaptive column visibility

**Deliverable:** Working three-column navigation structure

---

#### 4.2 BookListView (Sidebar)
**Priority:** Critical
**Estimated Time:** 2 hours

**Location:** `Views/BookListView.swift`

**UI Components:**
- List of all books
- Toolbar with "New Book" button
- Swipe-to-delete gesture
- Context menu (Rename, Delete)
- Empty state view
- Search bar (basic text filter)

**Key Features:**
```swift
- Custom row design matching Apple Notes
- SF Symbols for book icons
- Last modified date display
- Chapter count badge
- Selection highlighting
```

**Design Specs:**
- Typography: SF Pro Text, 16pt
- Row height: 44pt (iOS), 32pt (macOS)
- Icon: `book.fill` SF Symbol
- Subtitle: Last modified + chapter count

**Deliverable:** Fully functional book list with create/delete

---

#### 4.3 ChapterListView (Middle Column)
**Priority:** Critical
**Estimated Time:** 2 hours

**Location:** `Views/ChapterListView.swift`

**UI Components:**
- List of chapters in selected book
- Toolbar with "New Chapter" button
- Drag-and-drop reordering
- Swipe-to-delete
- Context menu (Rename, Duplicate, Delete)
- Word count per chapter

**Key Features:**
```swift
- Ordered chapter display (Chapter.order)
- Real-time word count updates
- Chapter numbering (Chapter 1, Chapter 2...)
- Content preview (first 50 characters)
```

**Design Specs:**
- Row shows: Title, word count, preview
- Support for list reordering with animation
- Empty state: "No chapters yet"

**Deliverable:** Chapter list with full management capabilities

---

#### 4.4 ChapterEditorView (Detail Pane)
**Priority:** Critical
**Estimated Time:** 3 hours

**Location:** `Views/ChapterEditorView.swift`

**UI Components:**
- Full-screen text editor (TextEditor)
- Toolbar with word/character count
- Title field (inline editing)
- Auto-save indicator
- Keyboard shortcuts (macOS)

**Key Features:**
```swift
- Debounced auto-save (1 second after typing stops)
- Real-time word and character count
- Markdown-friendly plain text
- Full Dynamic Type support
- Focus on editor by default
```

**Toolbar Items:**
- Word count: "1,234 words"
- Character count: "5,678 characters"
- Last saved: "Saved 2 seconds ago"

**Platform Differences:**
- iOS: Software keyboard, tap to dismiss
- macOS: Menu bar integration, Cmd+S manual save

**Deliverable:** Functional chapter editor with auto-save

---

### 5. Polish and UX Details

#### 5.1 Styling and Theming
**Priority:** Medium
**Estimated Time:** 1.5 hours

**Tasks:**
- Configure SF Pro Text as primary font
- Set up color scheme (system light/dark)
- Apply material/glass effects to sidebar
- Add subtle animations for list transitions
- Configure list row insets and spacing

**Design Alignment:**
- Match Apple Notes visual style exactly
- Use system colors for semantic meaning
- Support Dynamic Type across all views

**Deliverable:** Polished UI matching Apple HIG

---

#### 5.2 Empty States
**Priority:** Medium
**Estimated Time:** 1 hour

**Views to Create:**
- Empty BookListView: "No books yet. Tap + to create your first book."
- Empty ChapterListView: "No chapters. Start writing by adding a chapter."
- Welcome screen on first launch

**Deliverable:** User-friendly empty states throughout app

---

#### 5.3 Keyboard Shortcuts (macOS)
**Priority:** Medium
**Estimated Time:** 1 hour

**Shortcuts to Implement:**
- `Cmd+N`: New book (when sidebar focused) or new chapter (when list focused)
- `Cmd+S`: Manual save
- `Cmd+W`: Close window
- `Cmd+Delete`: Delete selected item
- `Cmd+F`: Focus search

**Deliverable:** macOS keyboard navigation support

---

### 6. Testing Infrastructure

#### 6.1 Unit Tests
**Priority:** Medium
**Estimated Time:** 2 hours

**Test Coverage:**
- Book model: CRUD operations, word count calculations
- Chapter model: Word count, character count
- ViewModel logic: Create, update, delete, reorder
- SwiftData persistence: Save and fetch operations

**Framework:** Swift Testing (Swift 6.1)

**Deliverable:** 70%+ code coverage on models and view models

---

#### 6.2 UI Tests
**Priority:** Low
**Estimated Time:** 1.5 hours

**Test Scenarios:**
- Create a new book
- Create a new chapter
- Edit chapter content and verify save
- Delete a book (with cascade delete verification)
- Reorder chapters

**Platforms:** iOS Simulator, macOS target

**Deliverable:** Basic UI test suite for critical paths

---

### 7. Documentation

#### 7.1 Code Documentation
**Priority:** Medium
**Estimated Time:** 1 hour

**Requirements:**
- DocC comments on all public models and methods
- README.md with build instructions
- Architecture overview diagram
- SwiftData schema documentation

**Deliverable:** Comprehensive inline documentation

---

#### 7.2 User-Facing Help
**Priority:** Low
**Estimated Time:** 30 minutes

**Content:**
- In-app tips for first-time users
- Keyboard shortcut reference (macOS)
- Basic usage guide

**Deliverable:** Help content accessible from settings

---

## Technical Requirements

### Swift 6.1 Compliance
- Enable strict concurrency checking
- Use `@MainActor` for UI-bound classes
- Leverage `@Observable` macro for view models
- Use `async/await` for future CloudKit integration

### Performance Targets
- List scrolling: 120Hz on ProMotion devices
- Chapter load time: <100ms
- Auto-save latency: <50ms after debounce
- Memory: <100MB for 50 books with 1000 chapters

### SwiftUI Best Practices
- Minimal use of `@State` – prefer `@Observable` view models
- Avoid force unwrapping – use optional binding
- Use `@Query` for SwiftData fetches
- Leverage `@Environment` for model context

---

## Phase One Deliverables

### Functional Deliverables
1. Working iOS and macOS app builds
2. Book and chapter creation/editing
3. Local persistence with SwiftData
4. Three-column navigation (Books → Chapters → Editor)
5. Word count tracking
6. Auto-save functionality
7. Chapter reordering

### Code Deliverables
1. Complete data models (Book, Chapter)
2. View models with CRUD operations
3. All primary views (BookList, ChapterList, Editor)
4. Unit test suite
5. Basic UI test coverage
6. Documentation (README, DocC comments)

### Quality Gates
- App builds without warnings
- All unit tests pass
- UI tests pass on iOS and macOS
- No force unwraps in production code
- Memory leaks resolved (Instruments validation)
- Adheres to Swift API Design Guidelines

---

## Success Metrics

### User Experience
- User can create and edit books/chapters without crashes
- Auto-save works reliably
- UI feels responsive (no dropped frames)
- Navigation is intuitive (matches Apple Notes)

### Code Quality
- 70%+ test coverage
- Zero compiler warnings
- SwiftLint passes (if configured)
- All views support Dynamic Type
- Dark mode works correctly

### Platform Compatibility
- Runs on iOS 26+ (iPhone and iPad)
- Runs on macOS 26+ (Apple Silicon and Intel)
- Adapts to different screen sizes
- Supports Split View on iPad

---

## Risk Mitigation

### Technical Risks
| Risk | Mitigation |
|------|------------|
| SwiftData performance with large datasets | Implement pagination and lazy loading early |
| Text editor performance on long chapters | Use TextEditor efficiently, test with 10k+ word chapters |
| Cross-platform layout issues | Test on both platforms continuously |
| Auto-save conflicts | Implement proper debouncing and conflict resolution |

### Schedule Risks
| Risk | Mitigation |
|------|------------|
| Underestimated complexity | Reduce scope (remove chapter reordering if needed) |
| SwiftUI API changes | Stick to stable APIs, avoid beta-only features |
| Testing takes longer than expected | Prioritize critical path tests |

---

## Post-Phase One Roadmap

### Phase Two (Future)
- CloudKit sync across devices
- Export to EPUB, PDF, DOCX
- Chapter templates
- Search and filtering
- Tags and metadata

### Phase Three (Future)
- AI integration (Claude API)
- Revision history
- Collaboration features
- Analytics dashboard

### Phase Four (Future)
- App extensions (widgets, share sheet)
- Marketing tools (keyword generator)
- Advanced formatting
- Focus mode and distraction-free writing

---

## Getting Started

### Prerequisites
- Xcode 16+ (with Swift 6.1 support)
- macOS 26 SDK
- iOS 26 SDK
- Apple Developer account (for device testing)

### Setup Steps
1. Clone repository
2. Open `Scrib.xcodeproj`
3. Select target (iOS or macOS)
4. Build and run (Cmd+R)

### Development Workflow
1. Create feature branch from `main`
2. Implement features following this plan
3. Write tests for new functionality
4. Submit PR with tests passing
5. Merge after code review

---

## Conclusion

Phase One establishes the foundation of Scrib as a production-ready book writing app. By focusing on core functionality and solid architecture, this phase sets up the project for rapid iteration and feature expansion in subsequent phases.

The emphasis on SwiftUI best practices, SwiftData persistence, and Apple HIG compliance ensures the app feels native and performant from day one.

**Next Step:** Begin implementation with Task 1.1 (Create Xcode Project)

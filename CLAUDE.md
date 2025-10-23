# Project: BookNotes — SwiftUI Book Writing App (iOS 26 & macOS 26)

## Overview
BookNotes is a cross-platform SwiftUI app for iOS and macOS that reimagines Apple Notes as a book-authoring environment.
Instead of folders and notes, the app uses **Books** (collections) and **Chapters** (entries). It blends minimalist design
with robust manuscript management tools, offering distraction-free writing, chapter organization, live syncing, and seamless
cross-device editing.

The user flow, layout, and interaction model closely mimic Apple Notes, while functionality draws from Scrivener-style
organization and modern SwiftUI paradigms.

---

## Technology and Standards
- **Languages:** Swift 6.1 (2025)
- **Frameworks:** SwiftUI (2025), Combine, CloudKit
- **Targets:** iOS 26, macOS 26 (Universal)
- **Design Guidelines:** Apple HIG 2025 + SwiftUI Best Practices
- **Performance Goals:** Maintain 120Hz scroll performance across 10,000+ chapters; zero dropped frames (per WWDC25 SwiftUI List benchmarks)
- **Architecture:** Model-View-ViewModel (MVVM) with scene isolation
- **Storage:** CloudKit (primary), CoreData (local fallback)

---

## Major Features

### 1. Writing Environment
- Full-screen, distraction-free writing mode with customizable backgrounds.
- Real-time word and character count displayed in the toolbar.
- Goal tracking (daily word count & per-book targets).
- AI-powered grammar, tone, and style improvements (Claude integration stub).

### 2. Book and Chapter Hierarchy
- Sidebar replicating Apple Notes' layout:
  - *Top Level:* List of Books.
  - *Nested Level:* Chapters within Books.
- Drag-and-drop reordering for chapters.
- Collapsible views (Books expand to show Chapters).
- Contextual menus for quick actions (rename, duplicate, move).

### 3. Organization Tools
- Metadata tagging (genre, completion status, keywords).
- Search and filter by title, tag, or content.
- Chapter templates for consistent formatting.
- Outliner view for high-level book overview (toggle via toolbar).

### 4. Editing and Productivity
- AI-driven sentence rewrites, summary generation, and creative prompts.
- Revision history with version diffs (per document version).
- Timer and focus mode similar to Apple Notes' pinned notes feature.
- Smart syntax highlighting for quotes or dialogues (via Markdown).

### 5. Formatting and Export
- Live preview of manuscript exports (EPUB, PDF, or DOCX).
- Book-level exports maintain chapter ordering.
- Ready-to-publish typography templates styled after Apple Books.
- Export metadata: title, author, description, ISBN placeholder.

### 6. Collaboration and Sync
- Real-time sync via CloudKit across devices.
- Comment mode for beta readers and editors.
- Share Book with permissions (View, Comment, Edit).
- Offline editing with automatic sync queue.

### 7. Marketing-Focused Integrations
- Keyword generator to suggest SEO-friendly titles and descriptions.
- Integration hooks for newsletter or social sharing.
- Dashboard for writing analytics (time spent, words per day, completion rate).

---

## Layout and Navigation Overview

### Structural Blueprint
**Primary View Layout:**
- **Sidebar (Books)** — mirrors Apple Notes' folder list.
- **Detail View (Chapters)** — lists all chapters for selected Book.
- **Editor View** — full SwiftTextView representing the chapter body.

**Navigation Flow:**
1. User opens sidebar (Books).
2. Selects book → chapter list appears in the second column.
3. Selecting a chapter opens editable view (Markdown-friendly text editor).
4. Top toolbar: export, outline, goals, comments, search.

**UI Principles:**
- Leverages `NavigationSplitView` and `NavigationStack`.
- Supports macOS classic split window with collapsible sidebar.
- "Glass" and "Material" effects inspired by iOS 26 Liquid Glass design system.

---

## SwiftUI Architecture Breakdown

### View Hierarchy
- `BookListView`: Displays all Books (sidebar)
- `ChapterListView`: Displays all Chapters within selected Book
- `ChapterEditorView`: Writing and editing view
- `AnalyticsDashboardView`: Tracks writing metrics
- `SettingsView`: Appearance, export, and sync preferences

### Data Model
```swift
struct Book: Identifiable, Codable {
    var id: UUID
    var title: String
    var genre: String
    var dateCreated: Date
    var lastModified: Date
    var chapters: [Chapter]
}

struct Chapter: Identifiable, Codable {
    var id: UUID
    var title: String
    var content: String
    var wordCount: Int
    var tags: [String]
    var lastModified: Date
}
```

### Persistence
- CloudKit containers for Books and Chapters with mirroring on CoreData.
- Unified data synchronization pipeline using `@Observable` macro + `CloudKitActor`.

---

## SwiftUI 2025-specific Features
- Uses **Scene Bridging** for iOS/macOS multitasking (per WWDC25 session 256).
- Employs **async sequences** for autosave and live progress updates.
- Applies **new transition APIs** for polished sidebar animations.
- Implements **LazyVSplit** for dynamic chapter loading (per Apple Developer Docs 2025).

---

## App Extensions
- **QuickNote Extension:** Add new chapters directly from Share Sheet.
- **MenuBarExtra (macOS):** Quick chapter creation shortcut.
- **Widgets:** Daily writing goals and streak reminders.

---

## Design Guidelines
- Typography and spacing should mirror Apple Notes exactly (SF Pro Text, 16pt).
- Toolbars use SF Symbols (SwiftUI 2025 `ToolbarItemGroup`).
- Utilize system Dynamic Type, color variants (light/dark).
- Apply new "glass" material backdrop for sidebar per Liquid Glass design system (WWDC25 demo).

---

## Future Roadmap
- AI auto-outline generation for Book structure.
- Collaboration rewrite integration via shared CloudKit zones.
- AI-based title recommender based on content themes.

---

## Testing and QA
- Unit tests: Swift 6 `Testing` module.
- UI tests on iPhone 16 Pro + MacBook Pro M4 (macOS 26).
- Continuous Integration: Xcode Cloud or CircleCI Swift pipeline.

---

## Summary
This project follows strict Swift 6.1 and SwiftUI 2025 conventions. It delivers a production-grade, Apple ecosystem-aligned writing tool
that merges Apple Notes' simplicity with Scrivener's depth and AI-assisted creativity. Every line of code should
follow Swift API design guidelines, performance best practices, and Apple's latest Human Interface Guidelines.

Deliver complete working prototypes and stubs for all major views, models, and persistence layers.

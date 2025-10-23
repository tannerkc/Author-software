# Build Instructions for Scrib

Since this repository contains Swift source files but not a pre-configured Xcode project, you'll need to create the Xcode project yourself. Follow these instructions to set up and build Scrib.

## Prerequisites

- macOS 15 (Sequoia) or later
- Xcode 16+ with Swift 6.1 support
- iOS 26 SDK and macOS 26 SDK

## Creating the Xcode Project

### Step 1: Create a New Xcode Project

1. Open Xcode
2. Select **File → New → Project**
3. Choose **Multiplatform → App**
4. Click **Next**

### Step 2: Configure Project Settings

- **Product Name**: `Scrib`
- **Organization Identifier**: `com.scrib` (or your own)
- **Bundle Identifier**: `com.scrib.Scrib`
- **Interface**: SwiftUI
- **Language**: Swift
- **Storage**: SwiftData (if prompted)
- **Include Tests**: ✅ Checked

### Step 3: Configure Build Settings

1. Select the project in the navigator
2. Go to **Build Settings**
3. Set **Swift Language Version**: Swift 6
4. Enable **Strict Concurrency Checking**: Yes
5. Set deployment targets:
   - **iOS Deployment Target**: 26.0
   - **macOS Deployment Target**: 26.0

### Step 4: Add Source Files

1. Delete the default `ContentView.swift` and `ScribApp.swift` that Xcode created
2. In Finder, navigate to the cloned repository
3. Drag the entire `Scrib` folder into your Xcode project
4. When prompted, select:
   - ✅ Copy items if needed
   - ✅ Create groups
   - ✅ Add to both iOS and macOS targets

### Step 5: Add Test Files

1. Drag the `ScribTests` folder into your Xcode project under the test target
2. Ensure the test files are added to the test target, not the main app target

### Step 6: Configure SwiftData

The project already includes SwiftData configuration in `ScribApp.swift`. No additional setup is needed.

## Building the Project

### For iOS

1. Select the iOS simulator from the scheme selector (e.g., iPhone 15 Pro)
2. Press **⌘R** to build and run
3. The app will launch in the iOS Simulator

### For macOS

1. Select **My Mac (Designed for Mac)** from the scheme selector
2. Press **⌘R** to build and run
3. The app will launch as a native macOS application

## Running Tests

1. Press **⌘U** to run all tests
2. Or select **Product → Test** from the menu
3. Tests will run on both iOS and macOS if both targets are configured

## Troubleshooting

### Build Errors

**Error**: "Cannot find type 'Book' in scope"
- **Solution**: Ensure all files in the `Models` folder are added to your target

**Error**: "Missing required module 'SwiftData'"
- **Solution**: Check that your deployment targets are set to iOS 26+ and macOS 26+

**Error**: Swift concurrency warnings
- **Solution**: Enable **Strict Concurrency Checking** in Build Settings

### Runtime Issues

**Issue**: App crashes on launch
- **Solution**: Check the console for SwiftData errors. Ensure the model schema is correct.

**Issue**: Sample data not created
- **Solution**: Delete the app and reinstall. The sample data is created on first launch only.

**Issue**: Changes not saving
- **Solution**: Check that SwiftData is properly configured and the model container is set in `ScribApp.swift`

## Project Structure Verification

After adding files, your Xcode project should look like this:

```
Scrib (Project)
├── Scrib (App Target)
│   ├── App/
│   │   └── ScribApp.swift
│   ├── Models/
│   │   ├── Book.swift
│   │   ├── Chapter.swift
│   │   └── DataStore.swift
│   ├── Views/
│   │   ├── ContentView.swift
│   │   ├── BookListView.swift
│   │   ├── ChapterListView.swift
│   │   ├── ChapterEditorView.swift
│   │   └── SettingsView.swift
│   ├── ViewModels/
│   │   ├── BookViewModel.swift
│   │   └── ChapterViewModel.swift
│   ├── Extensions/
│   │   ├── Date+Extensions.swift
│   │   └── Color+Extensions.swift
│   └── Resources/
│       └── Assets.xcassets
└── ScribTests (Test Target)
    ├── BookModelTests.swift
    └── ChapterModelTests.swift
```

## Optional: App Icon

To add an app icon:

1. Create a 1024×1024 PNG icon
2. Open `Assets.xcassets`
3. Add the icon to the AppIcon asset catalog
4. Xcode will automatically generate all required sizes

## Optional: Custom Bundle Settings

Edit `Info.plist` (if needed) to customize:
- App display name
- Supported orientations
- Required capabilities

## Performance Validation

After building, validate performance:

1. Run the app in Release mode: **Product → Scheme → Edit Scheme → Run → Build Configuration → Release**
2. Use Instruments to profile:
   - **Product → Profile** (⌘I)
   - Select **Time Profiler** or **Leaks**
3. Verify 120Hz scrolling on ProMotion devices

## Next Steps

Once the project builds successfully:

1. Read [README.md](README.md) for feature documentation
2. Read [PHASE_ONE_PLAN.md](PHASE_ONE_PLAN.md) for implementation details
3. Read [CLAUDE.md](CLAUDE.md) for the full project specification

## Support

For issues with:
- **Xcode setup**: Consult Apple's Xcode documentation
- **SwiftData**: Check Apple's SwiftData documentation
- **Scrib code**: Review the source files and comments

---

**Note**: This project was generated using Swift 6.1 and SwiftUI 2025 conventions. Ensure your Xcode version supports these features.

# Breadcrumb

Breadcrumb is a native macOS contextual memory layer.

**Leave a thought where it happened. Breadcrumb brings it back when you return.**

## V1

Breadcrumb currently includes:

- Native macOS menu-bar app
- Global `⌥ Space` capture shortcut
- Compact non-activating composer beside the pointer
- App and focused-window context detection
- Window-relative breadcrumb positioning
- Automatic hide/show when context changes
- Local persistence across app launches
- Draggable floating breadcrumb markers
- Click-to-open editor
- Edit and archive actions
- Searchable Breadcrumb library
- Archive and restore from the library
- First-run Accessibility onboarding
- Native Settings surface
- Light/Dark Mode through system materials
- Local development build currently runs without App Sandbox because cross-app Accessibility behavior is still being validated
- Automated macOS build and model/persistence tests

## Build locally

Requirements:

- macOS 14+
- Xcode
- XcodeGen

Install XcodeGen:

```bash
brew install xcodegen
```

Generate the project:

```bash
xcodegen generate
```

Open:

```bash
open Breadcrumb.xcodeproj
```

Run the **Breadcrumb** scheme.

Breadcrumb is a menu-bar utility, so it does not open a normal main window.

## First run

1. Open Breadcrumb.
2. Enable **Window Awareness** when prompted.
3. Open another app.
4. Press `⌥ Space`.
5. Type a thought and press Return.
6. Switch away and back to see the breadcrumb follow its context.

## Architecture

- **SwiftUI** — composer, editor, library, settings, onboarding
- **AppKit** — floating panels, menu bar, desktop/window behavior
- **Accessibility APIs** — focused-window metadata and geometry
- **NSWorkspace** — application activation
- **UserDefaults + Codable** — local V1 persistence

See `docs/PRODUCT.md`, `docs/DESIGN.md`, and `docs/ARCHITECTURE.md`.

## Privacy

V1 is local-first.

- No account
- No cloud backend
- No third-party analytics
- No note content leaves the Mac
- Screen capture is not used in V1

## Product rule

If a feature does not make it faster to leave a thought, easier to recover its context, or easier to resume thinking, it does not belong in V1.

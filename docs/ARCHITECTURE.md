# Breadcrumb — Architecture

## Stack
- Swift
- SwiftUI
- AppKit
- Accessibility APIs
- NSWorkspace
- SwiftData (after interaction proof)

## Modules
- App: lifecycle and menu bar scene
- HotkeyManager: global ⌥ Space
- ContextObserver: active app/window metadata
- ContextMatcher: decides which breadcrumbs belong to current context
- ComposerController: borderless capture window
- OverlayManager: breadcrumb windows
- BreadcrumbStore: persistence
- PermissionManager: Accessibility permission state
- History/Settings: SwiftUI surfaces

## First engineering milestone
Prove the interaction before persistence:
1. Launch as menu bar utility.
2. Register ⌥ Space.
3. Show composer beside pointer.
4. Enter text.
5. Render a draggable floating marker.
6. Switching applications hides/shows markers by bundle identifier.

Window-level matching and persistence come immediately after that proof.

# Breadcrumb

Breadcrumb is a native macOS contextual memory layer.

**Leave a thought where it happened. Breadcrumb brings it back when you return.**

Current beta: **0.10.1 (build 3)**

## What it does

- Native macOS menu-bar utility
- Configurable global capture shortcut
- Growing multiline capture palette
  - Return saves
  - Shift + Return inserts a new line
  - Escape closes
- App, focused-window, document, and available tab context detection
- Window-relative breadcrumb positioning
- Automatic hide/show as context changes
- Draggable floating breadcrumb markers
- Compact draggable micro-tabs with customizable accent colors
- Click-to-open full editable note
- Open / Done / Snoozed / Archived lifecycle with reopen, restore, and permanent delete
- Searchable Library grouped by application and context
- All / Active / Snoozed / Done / Archived Library filters
- Pick Up Where I Left Off summary
- Return-aware automatic resurfacing with persisted context-leave history
- Crowded contexts collapse into a compact stack at five or more breadcrumbs
- Local persistence with last-good backup recovery
- Privacy-safe support summary for beta reports
- First-run Accessibility onboarding
- Native Settings
- Launch at Login
- Light/Dark Mode through system UI and materials
- Automated macOS build and persistence/context tests

## Build and install locally

Requirements:

- macOS 14+
- Xcode
- XcodeGen

Install XcodeGen if needed:

```bash
brew install xcodegen
```

Then:

```bash
cd ~/breadcrumb-macos
git pull
zsh scripts/install-local.sh
```

The installer:

- regenerates the Xcode project
- performs a clean Release build
- signs using the configured Xcode development team
- verifies the signature
- replaces `/Applications/Breadcrumb.app`
- keeps generated build products under a Spotlight-excluded directory
- launches the installed app

Breadcrumb is a menu-bar utility, so it does not open a conventional main window.

## First run

1. Open Breadcrumb.
2. Enable **Window Awareness** when prompted.
3. Open another app.
4. Use the capture shortcut shown in Settings.
5. Type a thought and press Return.
6. Switch away and back to see the breadcrumb follow its context.

## Beta package

After installing a verified build:

```bash
zsh scripts/package-beta.sh
```

This creates a ZIP and SHA-256 checksum under `dist/`.

The current package uses the local development signing identity. Broad external distribution still requires **Developer ID signing and Apple notarization**.

## Architecture

- **SwiftUI** — composer, editor, Library, Settings, onboarding
- **AppKit** — floating panels, menu bar, window behavior
- **Accessibility APIs** — focused-window metadata and geometry
- **NSWorkspace** — application activation
- **Carbon hot keys** — global capture shortcut
- **UserDefaults + Codable** — local persistence with recovery backup

See:

- `docs/PRODUCT.md`
- `docs/DESIGN.md`
- `docs/ARCHITECTURE.md`
- `docs/RELIABILITY_CHECKLIST.md`
- `docs/BETA_TESTING.md`
- `docs/RELEASE_CHECKLIST.md`
- `docs/PRIVACY.md`

## Privacy

Breadcrumb is local-first.

- No account
- No third-party analytics
- No automatic upload of notes or diagnostics
- No Screen Recording permission in the current version

The local development build currently runs without App Sandbox while cross-app Accessibility behavior is validated.

## Product rule

If a feature does not make it faster to leave a thought, easier to recover its context, or easier to resume thinking, it does not belong in v1.

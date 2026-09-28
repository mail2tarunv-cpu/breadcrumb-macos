# Breadcrumb Privacy

Breadcrumb is designed as a local-first macOS utility.

## Stored locally

Breadcrumb stores:

- breadcrumb text
- application name and bundle identifier
- focused window title
- document URL when an app exposes one through Accessibility
- selected tab title/index when available
- window-relative marker position
- breadcrumb color
- archive/snooze state
- timestamps
- local diagnostics

## Permissions

Breadcrumb uses macOS Accessibility permission to identify the active window and available context metadata.

Breadcrumb does not use Screen Recording in the current version.

## Network

The current version has:

- no user account
- no cloud backend
- no analytics SDK
- no ad SDK
- no automatic upload of notes or diagnostics

## Diagnostics

Context Diagnostics can contain technical context used to explain matching behavior.

The separate **Copy Support Summary** action is intentionally reduced. It includes:

- Breadcrumb version/build
- macOS version
- Accessibility permission state
- diagnostic event counts
- recent diagnostic event categories and summaries

It omits breadcrumb note text and detailed diagnostic payloads.

## Deletion

Deleting a breadcrumb removes it from Breadcrumb's current local records. The local last-good backup is part of the app's data-recovery mechanism and is updated as subsequent valid saves occur.

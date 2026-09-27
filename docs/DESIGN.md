# Breadcrumb — Design Direction

Breadcrumb should feel like a macOS system capability, not an Apple-themed third-party app.

## Principles
- Native first: system typography, semantic colors, materials and SF Symbols.
- Invisible until needed.
- Minimal chrome.
- Fast capture: shortcut → type → Return.
- Motion is functional, subtle and short.
- Light/Dark Mode follows the system automatically.
- Keyboard access is first-class.
- Avoid oversized cards, decorative gradients and fake glass effects.

## Core object
Collapsed breadcrumb: a small circular marker.
Hover/click: reveals the thought in a compact material-backed popover.
Drag: repositions the anchor.
Archive: removes it from the active context while preserving history.

## Composer
- Appears beside pointer.
- Borderless.
- Compact.
- System material background.
- One text field.
- Return saves.
- Escape cancels.

## Motion
- Composer → marker: short scale/fade.
- Context enter: subtle fade/scale.
- Context leave: quick fade.
- No bounce.
- Respect Reduce Motion.

# Breadcrumb Reliability Checklist

Use this checklist for every release candidate. The goal is to verify that breadcrumbs remain attached to the intended context without disappearing, leaking into another context, or moving unexpectedly.

## Core capture and restore

For each supported app below:

- Create one breadcrumb.
- Switch to another app and confirm it hides.
- Return and confirm it reappears.
- Move and resize the target window and confirm the breadcrumb follows proportionally.
- Minimize and restore the window.
- Quit and relaunch Breadcrumb.
- Quit and relaunch the target app.
- Restart the Mac and verify persistence.

Apps:

- Safari
- Google Chrome
- Figma
- Finder
- Xcode
- Notes

## Browser tabs

Safari and Chrome:

- Two different URLs in the same window must not share breadcrumbs.
- Duplicate tabs with the same URL in the same process should remain distinct when tab identity is available.
- Reordered tabs should not move a breadcrumb to a different page.
- Closing and restoring a tab should recover the breadcrumb when the restored context identity matches.
- A page-title change should not orphan a breadcrumb when a stable document URL is still available.

## Multiple windows

For Safari, Finder, Figma, and Xcode:

- Open two windows with similar or identical titles.
- A breadcrumb created in one window must not appear in the other during the same process session.
- Closing one window must not affect breadcrumbs in the other.
- Relaunch and verify persisted breadcrumbs return to the strongest matching context available.

## Fullscreen and Spaces

- Move the target window to another Space.
- Enter and leave fullscreen.
- Switch Spaces rapidly.
- Confirm breadcrumbs appear only with the target context and do not remain floating over unrelated apps.

## Multiple displays

- Create a breadcrumb on display A.
- Move the target window to display B.
- Confirm the breadcrumb preserves its relative position in the window.
- Resize the window after moving displays.
- Disconnect/reconnect the secondary display and confirm the breadcrumb remains recoverable.

## Editing and dragging

- Open one breadcrumb while several are visible; only the edited breadcrumb should hide.
- Save and close; it should return to the same place.
- Drag one breadcrumb around nearby breadcrumbs.
- The dragged breadcrumb must remain under the pointer and keep its dropped position.
- Nearby breadcrumbs may resolve collisions, but the breadcrumb just moved should have placement priority.

## Snooze / archive / delete

- Snooze for one hour and one day.
- Quit/relaunch Breadcrumb; snoozed state should persist.
- Wake manually.
- Archive and restore.
- Delete from editor and Library using the inline confirmation.
- A deleted breadcrumb must not reappear after relaunch.

## Storage recovery

- Corrupt the primary local record payload in a development build.
- Relaunch.
- Breadcrumb should recover from the last-good local backup.
- Recovery should be visible in Context Diagnostics under the Storage category.
- Existing notes must not be silently replaced with an empty Library.

## Pass criteria

A release candidate passes only when:

1. no breadcrumb appears in a clearly unrelated context;
2. no valid breadcrumb disappears permanently after a normal relaunch;
3. drag/drop position remains stable;
4. persisted data survives relaunch and recovery tests;
5. no permission reset is required during an ordinary update.

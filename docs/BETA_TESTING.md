# Breadcrumb Beta Testing

Breadcrumb 0.9.0 is the first external-style beta candidate.

## What to test

Use Breadcrumb in normal work rather than creating artificial edge cases first.

Focus on:

1. Capture a breadcrumb from another app.
2. Return to that window or tab later.
3. Edit and move breadcrumbs.
4. Change the pastel dot color.
5. Snooze, archive, restore, and delete.
6. Open the Library.
7. Use Pick Up Where I Left Off.
8. Try a context with five or more breadcrumbs and confirm it collapses into one stack.
9. Change the capture shortcut in Settings.
10. Quit and relaunch both Breadcrumb and the target app.

Then run the full reliability checklist in `docs/RELIABILITY_CHECKLIST.md`.

## Feedback template

When reporting a problem, include:

- What you were trying to do
- What you expected
- What happened instead
- Target app and window/tab
- Whether it happens every time
- Screenshot or screen recording when useful
- Breadcrumb Support Summary

To copy the support summary:

Breadcrumb menu → Settings → Advanced → Copy Support Summary

The support summary intentionally omits breadcrumb note text and detailed diagnostic payloads.

## Current beta limitations

- Breadcrumb currently depends on macOS Accessibility permission.
- The current development build is not App Sandbox compatible.
- The current package is signed with the developer's local development identity.
- Broad external distribution still requires Developer ID signing and Apple notarization.
- Context identity quality varies by app because macOS apps expose Accessibility metadata differently.
- Cloud sync is not included.
- Screen capture is not used.

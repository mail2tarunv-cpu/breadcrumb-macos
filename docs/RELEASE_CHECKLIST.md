# Breadcrumb Release Checklist

Use this before every beta or release build.

## Code

- CI is green on main.
- No known data-loss regression.
- No permission reset is performed by the installer.
- Capture, edit, drag, color, snooze, archive, restore, delete, and Library all work.
- Pick Up Where I Left Off only resurfaces after a real return.
- Crowded contexts collapse at five or more breadcrumbs.
- Current version and build are set in `project.yml`.

## Manual reliability

Complete `docs/RELIABILITY_CHECKLIST.md`.

At minimum verify:

- Safari
- Chrome
- Figma
- Finder
- Xcode
- Notes
- multiple windows
- duplicate browser tabs
- fullscreen and Spaces
- multiple displays when available
- Breadcrumb relaunch
- target-app relaunch
- Mac restart

## Local build

Run:

```bash
cd ~/breadcrumb-macos
git pull
zsh scripts/install-local.sh
```

Confirm:

- `/Applications/Breadcrumb.app` launches.
- Accessibility remains enabled after an ordinary update.
- Spotlight shows the installed app as the canonical copy.
- Settings displays the intended version.
- Launch at Login can be toggled.

## Beta package

Run:

```bash
zsh scripts/package-beta.sh
```

Confirm:

- ZIP is created under `dist/`.
- SHA-256 checksum is created beside it.
- `codesign --verify --deep --strict` succeeds.

## External distribution gate

Do not describe a build as generally distributable until all of the following are true:

- Apple Developer Program distribution access is available.
- Developer ID Application signing is configured.
- Hardened Runtime remains enabled.
- The final archive is notarized by Apple.
- Stapling succeeds.
- Gatekeeper verification succeeds on a clean Mac.

The current Personal Team development signing is suitable for local development but is not the final external distribution identity.

## Beta feedback

Ask testers to include a screen recording where relevant and paste the privacy-safe Support Summary from Settings → Advanced.

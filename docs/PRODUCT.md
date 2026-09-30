# Breadcrumb — Product

## Product definition
Breadcrumb is a macOS contextual memory layer that lets people leave a thought on what they are working on and brings it back when they return.

## V1 loop
1. Press ⌥ Space.
2. Type a thought.
3. Press Return.
4. The thought collapses into a subtle breadcrumb marker.
5. Switching away hides it.
6. Returning to the matching app/window restores it.
7. Breadcrumbs persist across launches.

## V1 scope
- Menu bar app
- Global capture shortcut
- Composer near the pointer
- Draggable breadcrumb markers
- Active-app awareness
- Window awareness
- Local persistence
- Search/history
- Edit/archive
- First-run permission flow

## Explicitly out of scope for V1
- AI
- Collaboration
- Tasks/reminders/calendar
- Browser extension
- OCR
- Screenshot history
- Rich text
- Tags/folders

## Success criterion
Open Figma → create “Fix this spacing” → switch to Chrome → marker disappears → return to the same Figma context → marker reappears in place → restart Breadcrumb → it is still there.

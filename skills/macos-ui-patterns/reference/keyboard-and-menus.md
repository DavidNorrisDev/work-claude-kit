# Keyboard shortcuts and menu commands

## 5. Keyboard-complete and menu-driven

Mac power users expect to do everything from the keyboard. This is non-negotiable for a prosumer app.

- Every primary action has a keyboard shortcut (`.keyboardShortcut`).
- Expose commands in the menu bar (`CommandMenu`, `CommandGroup`) — the menu bar is a first-class surface, not a leftover.
- Manage focus deliberately (`@FocusState`, `.focusable`); tab order should make sense.
- Give every shortcut visible feedback. If triggering a shortcut produces no visible change, the user assumes it failed — a state change or micro-interaction is essential (see motion-system).
- **Check:** can the core workflow be completed without the mouse, and does every shortcut visibly respond?

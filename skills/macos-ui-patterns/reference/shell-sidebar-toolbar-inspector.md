# Shell: sidebar, toolbar, inspector

## 2. Structure: split view, toolbar, inspector

The canonical Mac shell is a `NavigationSplitView` — sidebar for navigation, content in the middle, an optional detail or `.inspector()` panel on the trailing edge for contextual detail about the current selection.

- Use the sidebar for primary navigation (`.listStyle(.sidebar)`), not a tab bar. If navigation is trivial (just browse and search), it's fine to drop the sidebar entirely and give the content the room.
- Use the unified toolbar (`.toolbar { ToolbarItem(...) }`) for view-level actions and `.searchable` for search.
- Use `.inspector()` for "details about the selected thing" rather than pushing to a new screen — ideal for analytics drill-downs.
- Keep the top ~50pt window-drag region uncluttered so the window stays draggable; integrate the traffic-light controls into the layout rather than crowding them. Let the top breathe.
- **Check:** is navigation in a sidebar, actions in the toolbar, contextual detail in an inspector — and is the top edge still draggable?

# Optimistic UI

## 7. Optimistic UI

Treat the common case as success. Update the UI immediately and reconcile with the backing store in the background, rather than blocking on confirmation.

- Apple Mail moves a message to Trash before the server confirms; follow that pattern for saves, deletes, and edits.
- Keep a quiet path to surface and recover from the rare failure, but don't make every user wait for it.
- **Check:** does the UI respond instantly to the user's action, or stall waiting on I/O?

---
name: swift6-concurrency
description: Swift 6 strict concurrency patterns. Use when writing or fixing actor isolation, Sendable conformance, @MainActor services, or when the build reports data-race / isolation errors.
---

# Swift 6 strict concurrency conventions

Load this when touching concurrency, actor isolation, or Sendable.

## Service shape (always this exact shape)
```swift
@MainActor @Observable
final class TaskService {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }
}
```
Inject via `.environment(taskService)`. Views read it with `@Environment(TaskService.self)`.

## Rules that prevent the common build failures
- Never mark a `@MainActor` type `Sendable` manually — it already is across the boundary.
- Background work: use `Task.detached` only for genuinely CPU-bound, model-free work. Anything touching `ModelContext` stays on `@MainActor`.
- `nonisolated` only for pure functions with no stored-property access.
- Closures passed to `Task {}` inherit `@MainActor` from the enclosing service — don't re-annotate.
- For SwiftData background writes use a separate `ModelContext` created from the container's `mainContext.container`, never share a context across actors.

## When the compiler complains
- "Sending 'x' risks causing data races" → the value crosses an isolation boundary. Make the type `Sendable` *or* move the work onto the right actor. Prefer moving the work.
- "Main actor-isolated property can not be referenced from a Sendable closure" → the closure escaped the actor. Wrap the body in `await MainActor.run { }` or make the closure `@MainActor`.

Address the root cause. Never silence with `@unchecked Sendable` or `nonisolated(unsafe)`.

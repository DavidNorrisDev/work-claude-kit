---
name: swiftdata-patterns
description: SwiftData modelling conventions — predicate-safe enums, singleton UserProfile, @Query usage, migrations. Use when adding/changing @Model types, writing #Predicate, or wiring queries into views.
---

# SwiftData patterns

## Enums in predicates → store as String rawValue
`#Predicate` cannot compare against an enum-typed stored property reliably.

```swift
@Model final class TaskItem {
    var zoneRaw: String = TaskZone.today.rawValue
    var zone: TaskZone {
        get { TaskZone(rawValue: zoneRaw) ?? .today }
        set { zoneRaw = newValue.rawValue }
    }
}
// Predicate filters on zoneRaw, never zone:
let today = #Predicate<TaskItem> { $0.zoneRaw == "today" }
```

## Singleton models (UserProfile pattern)
`UserProfile` is a singleton @Model with a cached subscription-tier mirror so
paywall checks never touch StoreKit synchronously. Fetch-or-create on first
access; never assume it exists.

## Views consume data via @Query only
```swift
@Query(filter: #Predicate<TaskItem> { $0.zoneRaw == "today" },
       sort: \.createdAt) private var todayTasks: [TaskItem]
```
Do not fetch inside `.task {}` / `onAppear` for display data — that defeats live updates.

## Migrations
Add new properties with defaults (lightweight migration). For anything else,
write an explicit `SchemaMigrationPlan` and note it in Journal.md. Never delete
a property without a migration stage.

## Widget data is one-way
The widget extension reads from shared `UserDefaults` in the App Group. It never
opens the SwiftData store. Writes flow app → UserDefaults → widget only.

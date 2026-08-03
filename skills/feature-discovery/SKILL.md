---
name: feature-discovery
description: A reusable FeatureDiscoveryManager pattern for surfacing feature tips/badges. Use when adding feature-discovery hints, "new" badges, or first-use callouts to any app.
---

# FeatureDiscoveryManager — a reusable pattern

A pure enum namespace. UserDefaults only. No SwiftData, no @Observable state,
no injected dependency. This keeps it trivially portable between apps.

## Contract
```swift
enum FeatureDiscoveryManager {
    static func hasSeen(_ feature: DiscoverableFeature) -> Bool
    static func markSeen(_ feature: DiscoverableFeature)
    static func reset()  // debug only
}
enum DiscoverableFeature: String, CaseIterable { /* per-app cases */ }
```

## Porting to a new app
1. Copy the enum verbatim.
2. Replace the `DiscoverableFeature` cases with that app's features.
3. Namespace the UserDefaults key with the app's bundle ID prefix so two
   apps on the same device don't collide.
4. Do NOT add persistence beyond UserDefaults. If a feature needs richer state,
   that is a different concern — don't grow this type.

## Usage rule
Discovery hints are advisory UI only. Never gate functionality behind
`hasSeen`. If the user dismisses, never re-show in the same install.

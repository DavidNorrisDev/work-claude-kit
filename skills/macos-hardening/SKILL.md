---
name: macos-hardening
description: macOS distribution hardening — App Sandbox, Hardened Runtime, entitlements design, code-signing identities, Gatekeeper, and TCC privacy prompts. Use when configuring or reviewing a Mac target's entitlements, choosing App Store vs Developer ID distribution, debugging "app is damaged"/quarantine/signing failures, or deciding which TCC usage descriptions a feature needs. For the shared Apple security APIs (Keychain, CryptoKit, Secure Enclave, biometrics) use swift-security; for the mechanical archive/export/notarize workflow use asc-notarization.
---

# macOS distribution hardening

The Mac-only surface between "it builds" and "it ships safely": sandboxing,
runtime hardening, entitlements, signing, Gatekeeper, and TCC. iOS-shaped
habits fail here — iOS grants none of these choices; macOS makes you take a
position on each.

## Boundaries (route deliberately)

- **`swift-security`** owns Keychain, CryptoKit, Secure Enclave,
  LocalAuthentication, credential storage, certificate pinning — the API
  surface shared with iOS.
- **`asc-notarization`** owns the mechanical archive → export → submit →
  staple workflow. This skill decides *what* gets signed with *which*
  entitlements; that one runs the pipeline.
- App Store *review/privacy-label* compliance is App Store Connect work, not
  hardening — out of scope here.

## App Sandbox

Mandatory for the Mac App Store; strongly recommended for Developer ID.
Everything is denied by default; each capability is an entitlement.

- `com.apple.security.app-sandbox` = `true` is the master switch. A Mac App
  Store submission without it is rejected.
- **File access is the big adjustment.** The sandbox allows the app's own
  container only. Beyond that, in order of preference:
  1. **User-selected file access** (`…files.user-selected.read-write`) — the
     open/save panel *is* the permission grant.
  2. **Security-scoped bookmarks** — persist access to user-chosen locations
     across launches (`com.apple.security.files.bookmarks.app-scope`); call
     `startAccessingSecurityScopedResource()`/`stop…` in balanced pairs.
  3. Named static locations (Downloads, Pictures, Music, Movies) via their
     specific entitlements — only when the panel flow genuinely doesn't fit.
- Network: `…network.client` for outgoing, `…network.server` only if the app
  genuinely listens. Don't add server "just in case" — every entitlement is
  attack surface and a review question.
- Temporary exceptions (`…temporary-exception.*`) are a smell: App Store
  review pushes back on them, and they usually mark a design that should use
  user-selected access or an XPC helper instead.
- Sandbox violations surface as silent failures or Console `sandboxd` denials
  — check Console before assuming a code bug when file or network calls
  no-op on macOS.

## Hardened Runtime

Required for notarization, therefore required for any distribution outside
the App Store. Independent of the sandbox — Developer ID apps need Hardened
Runtime even if unsandboxed; enable both unless there's a written reason.

- Default posture: **no exceptions**. Each runtime exception
  (`…cs.allow-jit`, `…cs.allow-unsigned-executable-memory`,
  `…cs.disable-library-validation`, `…cs.allow-dyld-environment-variables`)
  disables a protection Gatekeeper assumes is on. Add one only for a proven
  need (e.g. `allow-jit` for an embedded JS engine with JIT) and record why.
- `disable-library-validation` allows loading third-party-signed plug-ins —
  it also allows loading *anyone's* code. If the app has no plug-in
  architecture, never set it.
- Debugging tools (`get-task-allow`) are stripped in Release exports — a
  Debug-signed build failing notarization for this is expected; export for
  distribution instead.

## Entitlements design

- Entitlements are **claims baked into the code signature**; Info.plist
  usage strings are **user-facing explanations**. TCC-protected features
  need the matching `NS…UsageDescription` string or the API fails —
  sandboxed or not.
- Keep separate `.entitlements` files per distribution channel when App
  Store and Developer ID builds diverge (e.g. iCloud/push entitlements are
  provisioned differently); select per configuration, don't branch in one
  file with build settings.
- Keychain access groups and app groups are Team-ID-prefixed on macOS
  (`$(TeamIdentifierPrefix)`); a group string that works on iOS can still
  mismatch on the Mac target — verify with `codesign -d --entitlements -`.
- Push on macOS needs `com.apple.developer.aps-environment` (note: not the
  iOS `aps-environment` key) and a provisioning profile that carries it.
- Audit what's actually in the shipped binary, not what Xcode shows:

```bash
codesign -d --entitlements - --xml /path/to/App.app | plutil -p -
```

## Code signing

- **Identities:** `Apple Distribution` (App Store), `Developer ID
  Application` (direct distribution), `Developer ID Installer` (pkg).
  Development builds use `Apple Development`. Never ship ad-hoc (`-`) signed
  builds — Gatekeeper refuses them on other machines.
- Automatic signing is fine for development and App Store; Developer ID
  exports are where explicit identity + export options matter (see
  `asc-notarization` for the pipeline).
- Everything bundled must be signed inside-out (frameworks, XPC services,
  helpers, embedded CLIs) — `codesign --deep` is a diagnostic crutch, not a
  release tool; sign nested items explicitly via the build system.
- Verify like Gatekeeper will:

```bash
codesign --verify --deep --strict --verbose=2 /path/to/App.app
spctl --assess --type execute --verbose /path/to/App.app
```

## Gatekeeper

- First launch of a downloaded app: quarantine flag → Gatekeeper checks
  signature + notarization ticket. "App is damaged and can't be opened"
  usually means a broken/modified signature or missing notarization, not
  actual corruption.
- **Staple the ticket** (`xcrun stapler staple`) so first launch works
  offline; unstapled apps need a network round-trip to pass.
- Test the real first-run experience by re-adding quarantine to a local
  build: `xattr -w com.apple.quarantine "0083;00000000;Safari;" App.app` —
  a clean `spctl --assess` on an unquarantined copy proves nothing about
  what users see.
- Zip/dmg distribution must preserve the signature — use `ditto -c -k
  --keepParent`, not Finder compress, when scripting.

## TCC (privacy prompts)

TCC governs protected resources at *runtime*, on top of sandbox and
entitlements. macOS prompts for more than iOS does:

- Camera, microphone, location, contacts, calendars, photos — familiar from
  iOS; each needs its usage-description string.
- **Mac-specific:** Files & Folders (Desktop/Documents/Downloads access
  prompts even for *unsandboxed* apps), Full Disk Access (never grantable
  in-app; user must do it in System Settings), Screen Recording, Input
  Monitoring, and Automation/Apple Events
  (`NSAppleEventsUsageDescription` + `com.apple.security.automation.apple-events`
  for scripting other apps).
- A missing usage string doesn't prompt — the API returns denial or the app
  crashes. Add the string *and* handle the denied state with a path to
  System Settings (`x-apple.systempreferences:` URL).
- Reset grants while testing: `tccutil reset <Service> <bundle-id>` — test
  every feature from the never-asked state, not just the granted one.

## Hardening review checklist

- [ ] Sandbox on (or a written justification for why not), entitlement set
      is the minimum the feature set needs — no speculative entitlements.
- [ ] Hardened Runtime on with zero exceptions, or each exception justified
      in writing next to where it's set.
- [ ] Shipped-binary entitlements audited with `codesign -d --entitlements -`
      — matches intent, no Debug leftovers (`get-task-allow`).
- [ ] All nested code signed explicitly; `--deep --strict` verify passes.
- [ ] Developer ID builds notarized and stapled; first-run tested with the
      quarantine flag re-applied.
- [ ] Every TCC-protected feature has its usage string and a handled denial
      path; tested from the never-asked state via `tccutil reset`.
- [ ] File access uses user-selected flow or security-scoped bookmarks — no
      temporary exceptions without a recorded reason.

# Vendored third-party skills

Some skills under `skills/` are **not authored by this kit** — they're vetted,
frozen copies of community skills. They fill gaps the kit's own skills don't
cover and load on demand, so they don't tax every session.

## The model: vendored + pinned + reviewed (never live auto-update)

A skill is Markdown the agent *obeys*, so auto-pulling latest from third-party
repos would re-introduce unaudited instructions on every change — the opposite of
safe. Instead each skill is **copied in at a pinned commit, audited once, and only
ever moved forward by a human who has reviewed the diff.**

- **`vendored.manifest`** — the single source of truth: `dest | repo | pinned SHA | subpath | license | audited`.
- **`scripts/sync-vendored-skills.sh`** — materialises each skill at its pinned SHA (idempotent), copying only `SKILL.md` + `references/` + `LICENSE`, dropping marketplace/CI cruft and resolving symlinks.
- **`<skill>/UPSTREAM`** — provenance stamp inside each vendored dir (upstream, pin, license, audit date). `DO NOT EDIT` the vendored files: edits get overwritten on sync and make update diffs noisy.

## Keeping them up to date (safely)

```bash
scripts/sync-vendored-skills.sh --check   # report which upstreams moved past their pin
```

`--check` only *reports* — it lists new commits per skill and flags any new
non-Markdown/executable file as a re-audit trigger. To actually update one:
review the upstream diff → re-confirm it's safe → bump its SHA (and `audited`
date) in `vendored.manifest` → run `scripts/sync-vendored-skills.sh` (no flag) →
commit. Run `--check` on a regular cadence (e.g. weekly) so drift never piles up.
A `SessionStart` hook (`scripts/vendored-skills-drift-hook.sh`) also runs this
check in the background at most once a week and surfaces any drift as session
context, so it's rare you need to remember to run it by hand.

Skills reach a repo through the `wire-repo.sh` symlink (`.claude/skills` ->
this kit's `skills/` directory), so once a sync lands here, every wired repo
picks it up automatically on its next session — there's no separate
propagation step to run.

## Currently vendored

| Skill | Upstream author | Licence | Fills the gap |
|---|---|---|---|
| `swift-security` | dpearson2699 | **PolyForm Perimeter 1.0.0** | Apple security APIs: Keychain, CryptoKit, Secure Enclave, biometrics, pinning, OWASP MASVS (see below) |

## Apple security craft (`swift-security`)

**`swift-security`** (1 of ~85 in `dpearson2699/swift-ios-skills`, 884★) covers
the security API surface shared by iOS and macOS: Keychain Services, access
control, biometric-gated secrets, CryptoKit, Secure Enclave, credential storage,
certificate trust/pinning, legacy-secret migration, and OWASP MASVS/MASTG
compliance mapping. It pairs with the kit-authored **`macos-hardening`** skill,
which owns the Mac-only distribution surface (App Sandbox, Hardened Runtime,
entitlements, signing/notarization, Gatekeeper, TCC) that no vetted community
skill covers.

Audited 2026-08-03 → **ADOPT-WITH-CAVEATS**: markdown-only, no executables, no
prompt-injection; `compliance-owasp-mapping.md` documents audit tooling
(Frida/objection biometric-bypass hooks) in defensive MASTG framing.

**Licence: PolyForm Perimeter 1.0.0 — the only non-MIT vendored skill.**
Perimeter grants an explicit **Distribution License**, conditioned on the
**Notices** clause: anyone you give a copy to must also receive the licence
terms and every `Required Notice:` line from the licensor — satisfied here by
carrying `LICENSE` verbatim, which the sync does automatically. The live
restriction is **Noncompete**: the skill may not be used to provide a product
or service that competes with the licensed software. This repo is public, and
that is fine under those terms. (The upstream SKILL.md frontmatter says
`license: MIT` — a stale upstream error; the repo's root LICENSE governs and is
what `UPSTREAM` records.)

Its "Sibling Boundaries" section hands off to sibling skills not vendored here
(`authentication`, `cryptokit`, `device-integrity`, `ios-networking`,
`app-store-review`) — those handoffs are no-ops in this kit; add a manifest line
if one ever becomes worth carrying.

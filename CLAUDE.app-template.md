@CLAUDE.global.md

# <RepoName>

<!-- TODO: one-line description — what this app/service is and who it's for. -->

- Bundle ID: `com.company.RepoName`  <!-- verify against the Xcode project -->
- App Group: _none yet_  <!-- add the group ID here and in the entitlement if/when a widget or extension needs one -->
- Widget extension target: _none yet_
- Deployment target: iOS <!-- fill in --> / macOS <!-- fill in -->  <!-- verify against the deployment-target build setting -->
- SCHEME=<RepoScheme>  (export this before running build/test commands)

## Preserved implementations — DO NOT rewrite, only call into them
_None yet._ As shared managers/services land (networking clients, auth, logging),
list them here so they're reused rather than rewritten.

## Design tokens
<!-- If this repo has a design-token system, name the prefix/module and where
     tokens live (e.g. `Design/Tokens.swift`). Never hard-code a colour, spacing,
     or type value if a token exists; add one with the repo's convention if it
     doesn't. If there's no token system yet, delete this section. -->

## Repo-specific conventions
<!-- Anything that overrides or adds to CLAUDE.global.md for this repo:
     branch naming, PR/review process, CI quirks, third-party SDKs, an
     internal package registry, required code-signing/provisioning notes. -->

## Learned Patterns
Append dated `### YYYY-MM-DD — title` lessons to `docs/LEARNED.md` (loaded on
demand), NOT here — CLAUDE.md loads into context every session, so keep it
lean. This section stays a pointer.

# MyNorthStar — Claude Session Starter

Paste this at the start of any new Claude session working on MyNorthStar.

## Context

- **Project:** MyNorthStar — a SwiftUI/SwiftData app ("Know Your Values," a
  7-step values exercise), one multiplatform Xcode target (builds for
  iphoneos, iphonesimulator, and macosx from the same code), Swift 6,
  SwiftData local-only, bring-your-own Claude API key.
- **Local path (Paul's Mac mini):** `Lighthouse Logic/MyNorthStar/app/`
  contains `MyNorthStar.xcodeproj` and the `MyNorthStar/` source folder.
  Request access to the `Lighthouse Logic` folder if it isn't already
  connected this session.
- **GitHub:** `github.com/LighthouseLogic/MyNorthStar`, branch `main`. The
  repo also contains `core/`, `data/`, `elementary/` — an unrelated
  Vala/elementary-OS app. Never touch those paths.
- **Known environment constraint (don't re-test, just work around it):** the
  mounted `Lighthouse Logic` folder cannot have files deleted through
  Claude's file tools. Git constantly creates and deletes lock/temp files,
  so git operations (clone, commit, merge, push) must run in scratch space
  (e.g. `/tmp`), never directly against the mounted folder. After any
  accepted change, copy the finished files from scratch into
  `Lighthouse Logic/MyNorthStar/app/` so Xcode sees the current version.
- **Security control already in place:** an inline Run Script build phase in
  `MyNorthStar.xcodeproj` (`alwaysOutOfDate = 1`) fails the build if it finds
  an Anthropic API key pattern (`sk-ant-...`) or an api-key-looking string
  literal anywhere in source. A real key must only ever be entered by the
  app's end user into Settings, stored in Keychain — never in code.
- **Identifiers:** bundle ID `com.lighthouselogic.mynorthstar`, target/scheme
  name `MyNorthStar`.

## Action

Run this loop for each change Paul requests:

1. Clone/pull the latest `main` from `github.com/LighthouseLogic/MyNorthStar`
   into scratch space. If no GitHub PAT is available this session, ask Paul
   for one (fine-grained, scoped to this repo, Contents: Read and write).
2. Create a branch off `main` in scratch, make the requested edit, commit
   with a clear message.
3. Copy only the changed files from scratch into
   `Lighthouse Logic/MyNorthStar/app/` (leave `core/`, `data/`, `elementary/`
   untouched).
4. Tell Paul it's ready to test. Wait for him to build/run in Xcode and
   respond "accept" or "reject."
5. On accept: merge the branch to `main` in scratch, push to GitHub, confirm
   the push succeeded.
6. On reject: discard the branch in scratch, ask what to change, and repeat
   from step 2. Nothing touches `main` or GitHub until Paul explicitly
   accepts.

## Constraints

- Never run git directly against the mounted Lighthouse Logic folder —
  lock-file deletion will fail. Scratch space only.
- Never hardcode a real API key anywhere, even temporarily for testing —
  Keychain only, entered by the user in Settings.
- Don't modify `core/`, `data/`, `elementary/`, `LICENSE`, or the repo-root
  `README.md` unless Paul explicitly asks.
- Don't push to `main` without Paul's explicit "accept."
- If you don't have a GitHub PAT in context, ask for a fresh one — don't
  reuse or guess a token from a prior session.
- If Xcode reports a build error or warning, ask Paul to paste the exact
  text rather than guessing at the cause.

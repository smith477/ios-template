# ios-template

iOS app template. Clean architecture, Tuist-generated project, Core Data + REST.

## Requirements

- Xcode 26 or 27
- iOS 26 deployment target
- [mise](https://mise.jdx.dev) for toolchain versions

## Setup

The Xcode project is **generated** — it is not in source control. After cloning:

```bash
mise install                        # installs the pinned Tuist, SwiftLint, SwiftFormat
mise exec -- tuist install          # resolves Swift Package dependencies
mise exec -- tuist generate         # generates the .xcworkspace
```

`mise exec --` runs the pinned versions rather than whichever `tuist` is on your
`PATH`.

Open the generated `.xcworkspace`.

Editing targets, dependencies, or build settings means editing `Project.swift`
and re-running `tuist generate` — changes made in Xcode's project editor are
overwritten.

## Make it yours

One script turns the template into your app:

```bash
scripts/rename.sh "Acme Shop" com.acme acme
mise exec -- tuist install && mise exec -- tuist generate
```

- `"Acme Shop"` is the name on the home screen. Its slug, `acme-shop`, names the
  project, the workspace and the app's bundle ID, `com.acme.acme-shop`.
- `com.acme` prefixes every bundle ID.
- `acme` is the deep-link scheme: `acme://products/7`.

The script rewrites the four constants at the top of `Project.swift`, the names in
`Workspace.swift` and `Tuist/Package.swift`, and this README's title; everything
else is derived from those. It prints each change, can be re-run, and stops without
writing anything if a file no longer looks the way it expects. After it:

- Commit `Tuist/Package.resolved` too: `tuist install` rewrites its `originHash`
  for the new package name.
- Delete the old generated `.xcodeproj` and `.xcworkspace`.
- Point `API_BASE_URL` at your backend (see [Configuration](#configuration)).
- Keep `App/PrivacyInfo.xcprivacy` true to what the app does. It declares one
  required-reason API, `UserDefaults` for the product cache's timestamp
  (`CA92.1`), no tracking and no collected data. Update it whenever you add an SDK,
  call another [required-reason API](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api),
  or send user data to your backend.

A custom URL scheme is first-come on a device, so pick one you own; for
links that prove they belong to your app, Apple recommends universal links.

CI renames a copy to Acme on every run, so the script is known to work against the
current code.

## Commands

```bash
mise exec -- tuist generate                           # regenerate the project after changing Project.swift
mise exec -- tuist build                              # build
mise exec -- tuist test App --device "iPhone 18 Pro"  # run tests
```

`--device` is required: without it `tuist test` uses whichever simulator is
booted, and a different screen size puts UI-test taps in the wrong place. Use
iPhone 18 Pro on Xcode 27. On Xcode 26, which has no 18 Pro, use iPhone 17 Pro, as
CI does.

## Configuration

The API host is a build setting, not code. `API_BASE_URL` is set per build
configuration on the App target in `Project.swift`, reaches the app as the
`APIBaseURL` Info.plist key, and is read by `AppContainer.apiBaseURL`. Both Debug
and Release point at `https://dummyjson.com`; change those two values to give each
its own backend, then run `tuist generate`.

## Contributing

[AGENTS.md](AGENTS.md) holds the rules for this repo, for people and agents alike,
and the full command list. [docs/agents/](docs/agents/) covers architecture, testing
and conventions in depth.

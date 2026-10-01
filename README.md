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

## Commands

```bash
mise exec -- tuist generate                           # regenerate the project after changing Project.swift
mise exec -- tuist build                              # build
mise exec -- tuist test App --device "iPhone 17 Pro"  # run tests
```

`--device` is required: without it `tuist test` uses whichever simulator is
booted, and a different screen size puts UI-test taps in the wrong place. Xcode 27
ships no iPhone 17 Pro simulator; create one once with
`xcrun simctl create "iPhone 17 Pro" com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro`.

## Contributing

[AGENTS.md](AGENTS.md) holds the rules for this repo, for people and agents alike,
and the full command list. [docs/agents/](docs/agents/) covers architecture, testing
and conventions in depth.

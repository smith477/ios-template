# ios-template

iOS app template. Clean architecture, Tuist-generated project, Core Data + REST.

## Requirements

- Xcode 26
- iOS 26 deployment target
- [mise](https://mise.jdx.dev) for toolchain versions

## Setup

The Xcode project is **generated** — it is not in source control. After cloning:

```bash
mise install      # installs the pinned Tuist, SwiftLint, SwiftFormat
tuist install     # resolves Swift Package dependencies
tuist generate    # generates ios-template.xcworkspace
```

Open `ios-template.xcworkspace`.

Editing targets, dependencies, or build settings means editing `Project.swift`
and re-running `tuist generate` — changes made in Xcode's project editor are
overwritten.

## Commands

```bash
tuist generate    # regenerate the project after changing Project.swift
tuist build       # build
tuist test        # run tests
```

# Working in this repo

An iOS app template: Tuist-generated project, Swift 6, iOS 26, iPhone and iPad.
`App/` is the only place features are wired together. `Modules/Platform/*` and
`Modules/Features/*` are static frameworks.

Most decisions here are already explained in a comment next to the code that
makes them. The code is the source of truth: where it and these docs disagree,
the code wins and the doc is what gets corrected.

## Rules

**Never edit the Xcode project.** `ios-template.xcodeproj` and
`ios-template.xcworkspace` are generated and gitignored. Targets, dependencies,
build settings and schemes are edited in `Project.swift`, then regenerated with
`tuist generate`. Anything changed in Xcode's project editor is lost.

**A feature may never import another feature.** App may import every feature and
platform module. A feature may import platform modules and `APIClient`. Platform
imports nothing from this project. This is the boundary that keeps a feature
copyable into another project, which is what the template exists for.
`tuist inspect dependencies --only implicit` catches a violation. (CI still calls
the deprecated `tuist inspect implicit-imports` spelling; both work today.)

**Features never navigate.** A feature emits an event describing what happened;
`AppRouter` decides where it leads. See `docs/agents/architecture.md`.

**Never force unwrap.** `force_unwrapping`, `force_cast` and `force_try` are
SwiftLint errors, not warnings. Trap deliberately with `fatalError` naming what
broke. Test targets disable these rules; shipping code does not get an exemption.

**`import AppKit` means this project's Platform module**, not Apple's framework.

**Comments explain why, never what.** A comment that restates the code is noise
to delete.

**Do not add a dependency** — Swift package, test framework, or otherwise —
without asking first.

## Commands

```bash
mise install && mise exec -- tuist install && mise exec -- tuist generate
mise exec -- tuist build
mise exec -- tuist test App --device "iPhone 17 Pro"
mise exec -- tuist test ProductsTests --device "iPhone 17 Pro"
mise exec -- tuist inspect dependencies --only implicit
mise exec -- swiftformat . --lint && mise exec -- swiftlint lint --strict
```

`tuist generate` follows any `Project.swift` change, before building.

`--device "iPhone 17 Pro"` is not optional: `tuist test` otherwise picks whichever
simulator happens to be booted, and an older screen geometry puts UI-test taps in
the wrong place. `Project.swift` says so at the top.

## Commits

Subject line only — imperative, no body, no trailers, no `Co-Authored-By`. Match
what `git log` already looks like. Commit and push only when asked.

## Reference

Read the relevant file before working, rather than inferring from one example:

- `docs/agents/architecture.md` — before adding or changing a module, feature, or route
- `docs/agents/testing.md` — before writing or changing tests
- `docs/agents/conventions.md` — before writing Swift

import ProjectDescription

let tuist = Tuist(
    project: .tuist(
        // CI selects the newest Xcode 26 runner image; local machines may be on 27.
        compatibleXcodeVersions: .list([.upToNextMajor("26.0"), .upToNextMajor("27.0")])
    )
)

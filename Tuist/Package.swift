// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
        productTypes: ["APIClient": .framework]
    )
#endif

let package = Package(
    name: "ios-template",
    dependencies: [
        .package(url: "https://github.com/smith477/api-client", from: "1.0.0"),
    ]
)

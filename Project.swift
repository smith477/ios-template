import ProjectDescription

// The dependency rules this manifest enforces:
//
//   App       may import every feature and platform module. It is the only
//             place where features are wired together.
//   Feature   may import platform modules and APIClient.
//             A feature may never import another feature — that is the one
//             boundary worth a target, because it is what keeps a feature
//             copyable into another project.
//   Platform  imports nothing from this project. It knows no feature.
//
// Layers inside a feature (Domain / Data / Presentation) are folders, not
// targets. Split a feature into layer targets only once it is large enough to
// earn them; until then the ceremony costs more than it returns.

let deploymentTargets: DeploymentTargets = .iOS("26.0")
let destinations: Destinations = [.iPhone, .iPad]

// Tests run on iPhone 17 Pro. `tuist test` otherwise picks whichever
// simulator happens to be booted, and a device on an older screen geometry
// puts UI-test taps in the wrong place:
//
//     tuist test App --device "iPhone 17 Pro"
//
// The CI workflow passes the same flag.

let baseSettings: SettingsDictionary = [
    "SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY": "YES",
].swiftVersion("6.0")

// MainActor-by-default is a property of UI code, not of the project. Applied
// project-wide it lands on Domain types, storage and repositories — none of
// which touch the main actor — and every one of them then needs `nonisolated`
// to opt back out. Feature Presentation code carries its own `@MainActor`, and
// SwiftUI's `View` already supplies it, so only the App target takes it here.
let appSettings: SettingsDictionary = [
    "SWIFT_DEFAULT_ACTOR_ISOLATION": "MainActor",
]

func platform(
    _ name: String,
    dependencies: [TargetDependency] = [],
    coreDataModels: [CoreDataModel] = []
) -> Target {
    .target(
        name: name,
        destinations: destinations,
        product: .staticFramework,
        bundleId: "dusan.kovacevic.platform.\(name.lowercased())",
        deploymentTargets: deploymentTargets,
        sources: ["Modules/Platform/\(name)/Sources/**"],
        dependencies: dependencies,
        coreDataModels: coreDataModels
    )
}

func feature(_ name: String, dependencies: [TargetDependency] = []) -> Target {
    .target(
        name: name,
        destinations: destinations,
        product: .staticFramework,
        bundleId: "dusan.kovacevic.feature.\(name.lowercased())",
        deploymentTargets: deploymentTargets,
        sources: ["Modules/Features/\(name)/Sources/**"],
        dependencies: dependencies
    )
}

// A module's tests live beside it and use @testable, so a module needs no
// public surface for the sake of being tested. Tests that span modules — the
// container, routing — belong to the App target instead.
func tests(
    for name: String,
    at path: String,
    dependencies: [TargetDependency] = []
) -> Target {
    .target(
        name: "\(name)Tests",
        destinations: destinations,
        product: .unitTests,
        bundleId: "dusan.kovacevic.\(name.lowercased()).tests",
        deploymentTargets: deploymentTargets,
        sources: ["Modules/\(path)/\(name)/Tests/**"],
        dependencies: [.target(name: name)] + dependencies
    )
}

func featureTests(_ name: String, dependencies: [TargetDependency] = []) -> Target {
    tests(for: name, at: "Features", dependencies: dependencies)
}

func platformTests(_ name: String, dependencies: [TargetDependency] = []) -> Target {
    tests(for: name, at: "Platform", dependencies: dependencies)
}

let project = Project(
    name: "ios-template",
    // One scheme per target fills the picker with entries nobody selects on
    // purpose, including Tuist's internal resource-bundle target. The schemes
    // this project wants are declared at the bottom of this file instead.
    options: .options(automaticSchemesOptions: .disabled),
    settings: .settings(base: baseSettings),
    targets: [
        platform("Identity"),
        platform("AppKit"),
        platform(
            "Persistence",
            coreDataModels: [
                .coreDataModel("Modules/Platform/Persistence/Sources/ios_template.xcdatamodeld"),
            ]
        ),

        feature(
            "Products",
            dependencies: [
                .target(name: "Identity"),
                .target(name: "AppKit"),
                .target(name: "Persistence"),
                .external(name: "APIClient"),
            ]
        ),
        feature(
            "Users",
            dependencies: [
                .target(name: "Identity"),
                .target(name: "AppKit"),
                .target(name: "Persistence"),
                .external(name: "APIClient"),
            ]
        ),

        featureTests(
            "Products",
            dependencies: [
                .target(name: "AppKit"),
                .target(name: "Persistence"),
                .external(name: "APIClient"),
            ]
        ),
        platformTests("AppKit"),

        .target(
            name: "App",
            destinations: destinations,
            product: .app,
            productName: "App",
            bundleId: "dusan.kovacevic.ios-template",
            deploymentTargets: deploymentTargets,
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [:],
                // Tuist's default plist requires armv7, which no simulator
                // reports — it hides every simulator from the run destinations.
                "UIRequiredDeviceCapabilities": ["arm64"],
            ]),
            sources: ["App/**"],
            resources: ["App/Assets.xcassets"],
            dependencies: [
                .target(name: "Products"),
                .target(name: "Users"),
                .target(name: "AppKit"),
                .target(name: "Persistence"),
                .external(name: "APIClient"),
            ],
            settings: .settings(base: appSettings)
        ),
        .target(
            name: "AppTests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "dusan.kovacevic.AppTests",
            deploymentTargets: deploymentTargets,
            sources: ["AppTests/**"],
            dependencies: [
                .target(name: "App"),
                .target(name: "Products"),
                .target(name: "Users"),
                .target(name: "Persistence"),
                .external(name: "APIClient"),
            ]
        ),
        .target(
            name: "AppUITests",
            destinations: destinations,
            product: .uiTests,
            bundleId: "dusan.kovacevic.AppUITests",
            deploymentTargets: deploymentTargets,
            sources: ["AppUITests/**"],
            dependencies: [
                .target(name: "App"),
            ]
        ),
    ],
    schemes: [
        // Everything: what CI runs, and the scheme to pick when running the app.
        .scheme(
            name: "App",
            shared: true,
            buildAction: .buildAction(targets: ["App"]),
            testAction: .targets(["AppTests", "ProductsTests", "AppKitTests", "AppUITests"]),
            runAction: .runAction(executable: "App")
        ),

        // One scheme per test bundle, so a module's tests can be run on their
        // own from the scheme picker without waiting for the rest. Declared
        // rather than generated: automatic schemes would also add one for
        // every framework and for Tuist's internal resource-bundle target.
        testScheme("ProductsTests"),
        testScheme("AppKitTests"),
        testScheme("AppTests"),
        testScheme("AppUITests"),
    ]
)

func testScheme(_ target: String) -> Scheme {
    .scheme(
        name: target,
        shared: true,
        buildAction: .buildAction(targets: ["\(target)"]),
        testAction: .targets(["\(target)"])
    )
}

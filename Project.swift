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

let baseSettings: SettingsDictionary = [
    "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
    "SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY": "YES",
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

let project = Project(
    name: "ios-template",
    settings: .settings(base: baseSettings),
    targets: [
        platform(
            "Persistence",
            coreDataModels: [
                .coreDataModel("Modules/Platform/Persistence/Sources/ios_template.xcdatamodeld"),
            ]
        ),

        feature(
            "Products",
            dependencies: [
                .target(name: "Persistence"),
                .external(name: "APIClient"),
            ]
        ),
        feature(
            "Users",
            dependencies: [
                .target(name: "Persistence"),
                .external(name: "APIClient"),
            ]
        ),

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
                .target(name: "Persistence"),
                .external(name: "APIClient"),
            ]
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
    ]
)

import ProjectDescription

let deploymentTargets: DeploymentTargets = .iOS("26.0")
let destinations: Destinations = [.iPhone, .iPad]

let baseSettings: SettingsDictionary = [
    "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
    "SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY": "YES",
]

let project = Project(
    name: "ios-template",
    settings: .settings(base: baseSettings),
    targets: [
        .target(
            name: "ios-template",
            destinations: destinations,
            product: .app,
            productName: "ios-template",
            bundleId: "dusan.kovacevic.ios-template",
            deploymentTargets: deploymentTargets,
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [:],
            ]),
            sources: ["ios-template/**"],
            resources: ["ios-template/Assets.xcassets"],
            dependencies: [
                .external(name: "APIClient"),
            ],
            coreDataModels: [
                .coreDataModel("ios-template/ios_template.xcdatamodeld"),
            ]
        ),
        .target(
            name: "ios-templateTests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "dusan.kovacevic.ios-templateTests",
            deploymentTargets: deploymentTargets,
            sources: ["ios-templateTests/**"],
            dependencies: [
                .target(name: "ios-template"),
            ]
        ),
        .target(
            name: "ios-templateUITests",
            destinations: destinations,
            product: .uiTests,
            bundleId: "dusan.kovacevic.ios-templateUITests",
            deploymentTargets: deploymentTargets,
            sources: ["ios-templateUITests/**"],
            dependencies: [
                .target(name: "ios-template"),
            ]
        ),
    ]
)

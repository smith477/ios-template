import ProjectDescription

// App may import any module. A feature may import Platform modules and APIClient,
// never another feature. Platform imports nothing here. See docs/agents/architecture.md.

// The app's identity, rewritten by `scripts/rename.sh`. Every name, bundle ID and
// URL scheme below derives from these lines.
let appName = "ios-template"
let displayName = "Template"
let bundlePrefix = "dusan.kovacevic"
let urlScheme = "template"

let deploymentTargets: DeploymentTargets = .iOS("26.0")
let destinations: Destinations = [.iPhone, .iPad]

let baseSettings: SettingsDictionary = [
    "SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY": "YES",
].swiftVersion("6.0")

// App target only: project-wide, MainActor-by-default would force `nonisolated`
// onto every Domain and Data type.
let appSettings: SettingsDictionary = [
    "SWIFT_DEFAULT_ACTOR_ISOLATION": "MainActor",
]

func platform(_ name: String, dependencies: [TargetDependency] = []) -> Target {
    .target(
        name: name,
        destinations: destinations,
        product: .staticFramework,
        bundleId: "\(bundlePrefix).platform.\(name.lowercased())",
        deploymentTargets: deploymentTargets,
        sources: ["Modules/Platform/\(name)/Sources/**"],
        dependencies: dependencies
    )
}

func feature(
    _ name: String,
    dependencies: [TargetDependency] = [],
    coreDataModels: [CoreDataModel] = []
) -> Target {
    .target(
        name: name,
        destinations: destinations,
        product: .staticFramework,
        bundleId: "\(bundlePrefix).feature.\(name.lowercased())",
        deploymentTargets: deploymentTargets,
        sources: ["Modules/Features/\(name)/Sources/**"],
        dependencies: dependencies,
        coreDataModels: coreDataModels
    )
}

// Tests live beside their module and use `@testable`, so nothing is made public
// for a test. Tests that span modules belong to AppTests.
func tests(
    for name: String,
    at path: String,
    dependencies: [TargetDependency] = [],
    coreDataModels: [CoreDataModel] = []
) -> Target {
    .target(
        name: "\(name)Tests",
        destinations: destinations,
        product: .unitTests,
        bundleId: "\(bundlePrefix).\(name.lowercased()).tests",
        deploymentTargets: deploymentTargets,
        sources: ["Modules/\(path)/\(name)/Tests/**"],
        dependencies: [.target(name: name)] + dependencies,
        coreDataModels: coreDataModels
    )
}

func featureTests(_ name: String, dependencies: [TargetDependency] = []) -> Target {
    tests(for: name, at: "Features", dependencies: dependencies)
}

func platformTests(
    _ name: String,
    dependencies: [TargetDependency] = [],
    coreDataModels: [CoreDataModel] = []
) -> Target {
    tests(for: name, at: "Platform", dependencies: dependencies, coreDataModels: coreDataModels)
}

let project = Project(
    name: appName,
    // Automatic schemes add one per framework and resource bundle; the wanted
    // schemes are declared at the bottom instead.
    options: .options(automaticSchemesOptions: .disabled),
    settings: .settings(base: baseSettings),
    targets: [
        platform("Persistence"),

        feature(
            "Products",
            dependencies: [
                .target(name: "Persistence"),
                .external(name: "APIClient"),
            ],
            coreDataModels: [
                .coreDataModel("Modules/Features/Products/Sources/Products.xcdatamodeld"),
            ]
        ),
        feature(
            "Users",
            dependencies: [
                .target(name: "Persistence"),
                .external(name: "APIClient"),
            ],
            coreDataModels: [
                .coreDataModel("Modules/Features/Users/Sources/Users.xcdatamodeld"),
            ]
        ),

        featureTests(
            "Products",
            dependencies: [
                .target(name: "Persistence"),
                .external(name: "APIClient"),
            ]
        ),
        // Small models of its own, so merging and migration are tested without a
        // feature.
        platformTests(
            "Persistence",
            coreDataModels: [
                .coreDataModel("Modules/Platform/Persistence/Tests/Models/First.xcdatamodeld"),
                .coreDataModel("Modules/Platform/Persistence/Tests/Models/Second.xcdatamodeld"),
                .coreDataModel("Modules/Platform/Persistence/Tests/Models/Versioned.xcdatamodeld"),
            ]
        ),

        .target(
            name: "App",
            destinations: destinations,
            product: .app,
            productName: "App",
            bundleId: "\(bundlePrefix).\(appName)",
            deploymentTargets: deploymentTargets,
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [:],
                // Without it the home screen shows the product name, `App`.
                "CFBundleDisplayName": .string(displayName),
                // Tuist's default requires armv7, which hides every simulator
                // from the run destinations.
                "UIRequiredDeviceCapabilities": ["arm64"],
                // A custom scheme is first-come on device: a shipping app wants a
                // name it owns, or universal links.
                "CFBundleURLTypes": [
                    [
                        "CFBundleURLName": "\(bundlePrefix).\(appName)",
                        "CFBundleURLSchemes": [.string(urlScheme)],
                    ],
                ],
                // Read by `DeepLink`. A key of its own, because SDKs append their
                // callback schemes to CFBundleURLTypes.
                "DeepLinkScheme": .string(urlScheme),
                // Expanded per build configuration from `API_BASE_URL` below.
                "APIBaseURL": "$(API_BASE_URL)",
            ]),
            sources: ["App/**"],
            // The README says when PrivacyInfo.xcprivacy has to change.
            resources: ["App/Assets.xcassets", "App/PrivacyInfo.xcprivacy"],
            dependencies: [
                .target(name: "Products"),
                .target(name: "Users"),
                .target(name: "Persistence"),
                .external(name: "APIClient"),
            ],
            // The backend per build: point Debug at staging and Release at
            // production here.
            settings: .settings(
                base: appSettings,
                configurations: [
                    .debug(name: .debug, settings: ["API_BASE_URL": "https://dummyjson.com"]),
                    .release(name: .release, settings: ["API_BASE_URL": "https://dummyjson.com"]),
                ]
            )
        ),
        .target(
            name: "AppTests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "\(bundlePrefix).AppTests",
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
            bundleId: "\(bundlePrefix).AppUITests",
            deploymentTargets: deploymentTargets,
            sources: ["AppUITests/**"],
            dependencies: [
                .target(name: "App"),
            ]
        ),
    ],
    schemes: [
        // Runs the app and every test bundle; what CI runs.
        .scheme(
            name: "App",
            shared: true,
            buildAction: .buildAction(targets: ["App"]),
            testAction: .targets(["AppTests", "ProductsTests", "PersistenceTests", "AppUITests"]),
            runAction: .runAction(executable: "App")
        ),

        // One scheme per test bundle, to run a module's tests on their own.
        testScheme("ProductsTests"),
        testScheme("PersistenceTests"),
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

// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "Bugsnag",
    platforms: [
        .macOS(.v10_11),
        .tvOS("9.2"),
        .iOS("9.3"),
    ],
    products: [
        .library(name: "Bugsnag", targets: ["Bugsnag"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Bugsnag",
            dependencies: [],
            path: "Bugsnag",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("."),
                .headerSearchPath("Breadcrumbs"),
                .headerSearchPath("Client"),
                .headerSearchPath("Configuration"),
                .headerSearchPath("Delivery"),
                .headerSearchPath("Helpers"),
                .headerSearchPath("include/Bugsnag"),
                .headerSearchPath("KSCrash"),
                .headerSearchPath("KSCrash/Source/KSCrash/Recording"),
                .headerSearchPath("KSCrash/Source/KSCrash/Recording/Sentry"),
                .headerSearchPath("KSCrash/Source/KSCrash/Recording/Tools"),
                .headerSearchPath("KSCrash/Source/KSCrash/Reporting/Filters"),
                .headerSearchPath("Metadata"),
                .headerSearchPath("Payload"),
                .headerSearchPath("Plugins"),
                .headerSearchPath("Storage"),
            ],
            linkerSettings: [
                .linkedLibrary("z"),
                .linkedLibrary("c++"),
            ]
        ),
    ],
    cLanguageStandard: .gnu11,
    cxxLanguageStandard: .gnucxx14
)

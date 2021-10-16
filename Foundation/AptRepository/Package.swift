// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AptRepository",
    platforms: [
        .iOS(.v13),
        .macOS(.v11),
        .tvOS(.v11),
        .watchOS(.v6),
    ],
    products: [
        .library(name: "AptRepository", targets: ["AptRepository"]),
    ],
    dependencies: [
        .package(name: "Dog", path: "../Dog"),
        .package(name: "SWCompression", path: "../SWCompression"),
        .package(name: "SwiftThrottle", path: "../SwiftThrottle"),
        .package(name: "PropertyWrapper", path: "../PropertyWrapper"),
        .package(name: "AptPackageVersion", path: "../AptPackageVersion"),
    ],
    targets: [
        .target(
            name: "AptRepository",
            dependencies: [
                "Dog",
                "SwiftThrottle",
                "PropertyWrapper",
                "SWCompression",
                "AptPackageVersion",
            ]
        ),
    ]
)

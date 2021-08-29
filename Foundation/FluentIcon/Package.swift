// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
let package = Package(
    name: "FluentIcon",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "FluentIcon",
            targets: ["FluentIcon"]
        ),
    ],
    targets: [
        .target(
            name: "FluentIcon",
            dependencies: [],
            resources: [.process("Assets")]
        ),
    ]
)

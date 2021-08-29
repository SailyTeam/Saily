// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Digger",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Digger",
            targets: ["Digger"]
        ),
    ],
    dependencies: [
        .package(name: "SwiftMD5", path: "../SwiftMD5"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Digger",
            dependencies: ["SwiftMD5"]
        ),
    ]
)

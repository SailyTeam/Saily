// swift-tools-version: 5.5

import PackageDescription

let package = Package(
    name: "PathListTableViewController",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "PathListTableViewController",
            targets: ["PathListTableViewController"]
        ),
    ],
    targets: [
        .target(
            name: "PathListTableViewController",
            dependencies: []
        ),
    ]
)

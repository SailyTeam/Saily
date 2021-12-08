// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AuxiliaryExecute",
    products: [
        .library(
            name: "AuxiliaryExecute",
            targets: ["AuxiliaryExecute"]
        ),
    ],
    targets: [
        .target(
            name: "AuxiliaryExecute",
            dependencies: []
        ),
        .testTarget(
            name: "AuxiliaryExecuteTests",
            dependencies: ["AuxiliaryExecute"]
        ),
    ]
)

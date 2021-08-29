// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AptPackageVersion",
    products: [
        .library(
            name: "AptPackageVersion",
            targets: ["AptPackageVersion"]
        ),
    ],
    targets: [
        .target(
            name: "AptPackageVersion"
        ),
    ]
)

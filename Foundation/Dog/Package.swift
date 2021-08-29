// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "Dog",
    products: [
        .library(name: "Dog", targets: ["Dog"]),
    ],
    targets: [
        .target(name: "Dog", dependencies: []),
        .testTarget(name: "DogTests", dependencies: ["Dog"]),
    ]
)

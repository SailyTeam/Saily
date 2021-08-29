// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "SwiftThrottle",
    products: [
        .library(
            name: "SwiftThrottle",
            targets: ["SwiftThrottle"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "SwiftThrottle",
            dependencies: []
        ),
        .testTarget(
            name: "SwiftThrottleTests",
            dependencies: ["SwiftThrottle"]
        ),
    ]
)

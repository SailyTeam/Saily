// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "MorphingLabel",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(name: "MorphingLabel", targets: ["MorphingLabel"]),
    ],
    targets: [
        .target(
            name: "MorphingLabel",
            resources: [
                .process("Particles"),
            ]
        ),
    ]
)

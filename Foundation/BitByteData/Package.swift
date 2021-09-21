// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "BitByteData",
    products: [
        .library(
            name: "BitByteData",
            targets: ["BitByteData"]
        ),
    ],
    targets: [
        .target(name: "BitByteData", path: "Sources"),
    ],
    swiftLanguageVersions: [.v5]
)

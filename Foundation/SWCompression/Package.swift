// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "SWCompression",
    products: [
        .library(
            name: "SWCompression",
            targets: ["SWCompression"]
        ),
    ],
    dependencies: [
        .package(name: "BitByteData", path: "../BitByteData"),
    ],
    targets: [
        .target(
            name: "SWCompression",
            dependencies: ["BitByteData"],
            path: "Sources",
            sources: [
                "Common",
                "7-Zip", "BZip2",
                "Deflate",
                "GZip",
                "LZMA", "LZMA2",
                "TAR",
                "XZ",
                "ZIP", "Zlib",
            ]
        ),
    ]
)

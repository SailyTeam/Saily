// swift-tools-version:5.1
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
        // SWCOMP: Uncomment the line below to build swcomp example program.
        // .package(url: "https://github.com/jakeheis/SwiftCLI",
        //          from: "6.0.0"),
        .package(url: "https://github.com/tsolomko/BitByteData",
                 from: "2.0.0"),
    ],
    targets: [
        // SWCOMP: Uncomment the lines below to build swcomp example program.
        // .target(
        //     name: "swcomp",
        //     dependencies: ["SWCompression", "SwiftCLI"],
        //     path: "Sources",
        //     sources: ["swcomp"]),
        .target(
            name: "SWCompression",
            dependencies: ["BitByteData"],
            path: "Sources",
            sources: ["Common", "7-Zip", "BZip2", "Deflate", "GZip", "LZ4", "LZMA", "LZMA2", "TAR", "XZ", "ZIP", "Zlib"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)

// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JsonDepiction",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "JsonDepiction",
            targets: ["JsonDepiction"]
        ),
    ],
    dependencies: [
        .package(name: "FLAnimatedImage", path: "../FLAnimatedImage"),
        .package(name: "SDWebImage", path: "../SDWebImage"),
        .package(name: "Down", path: "../Down"),
        .package(name: "Cosmos", path: "../Cosmos"),
        .package(name: "DTPhotoViewerController", path: "../DTPhotoViewerController"),
    ],
    targets: [
        .target(
            name: "JsonDepiction",
            dependencies: [
                "FLAnimatedImage",
                "SDWebImage",
                "Down",
                "Cosmos",
                "DTPhotoViewerController",
            ]
        ),
    ]
)

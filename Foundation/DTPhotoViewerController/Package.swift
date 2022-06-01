// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "DTPhotoViewerController",
    platforms: [
        .iOS(.v10),
    ],
    products: [
        .library(name: "DTPhotoViewerController", targets: ["DTPhotoViewerController"]),
    ],
    targets: [
        .target(
            name: "DTPhotoViewerController",
            path: "DTPhotoViewerController/Classes"
        ),
    ]
)

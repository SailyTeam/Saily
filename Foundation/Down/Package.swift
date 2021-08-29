// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Down",
    platforms: [
        .macOS("10.11"),
        .iOS("9.0"),
        .tvOS("9.0"),
    ],
    products: [
        .library(
            name: "Down",
            targets: ["Down"]
        ),
    ],
    targets: [
        .target(
            name: "libcmark",
            dependencies: [],
            path: "Sources/cmark",
            exclude: [
                "include",
                "case_fold_switch.inc",
                "entities.inc",
                "COPYING",
            ],
            publicHeadersPath: "./"
        ),
        .target(
            name: "Down",
            dependencies: ["libcmark"],
            path: "Sources/Down",
            exclude: ["Down.h"],
            resources: [
                .copy("Resources/DownView.bundle"),
                .copy("Resources/DownView (macOS).bundle"),
            ]
        ),
    ]
)

// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NDI",
    products: [
        .library(name: "NDI", targets: ["NDI"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "NDI",
            dependencies: ["libndi"],
            linkerSettings: [
                .linkedFramework("Accelerate"),
                .linkedFramework("VideoToolbox"),
                .linkedLibrary("c++")
            ]
        ),
        .systemLibrary(name: "libndi", pkgConfig: "libndi_ios")
    ]
)

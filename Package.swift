// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ResponsiveLabel",
    platforms: [.iOS(.v12)],
    products: [
        .library(
            name: "ResponsiveLabel",
            targets: ["ResponsiveLabel"]
        ),
    ],
    targets: [
        .target(
            name: "ResponsiveLabel",
            path: "ResponsiveLabel/ResponsiveLabel/Source",
            publicHeadersPath: "."
        )
    ]
)

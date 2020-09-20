// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(

    name: "Snippets",

    platforms: [
        .iOS(.v10),
        .macOS(.v10_15)
    ],

    products: [
        .library(
            name: "Snippets",
            targets: ["Snippets"]),
    ],

    dependencies: [
        .package(
                    url: "https://github.com/SilverPineSoftware/UUSwift.git",
                    from: "1.0.3"
                )
    ],

    targets: [
        .target(
            name: "Snippets",
            dependencies: [ "UUSwift" ],
            path: "Snippets",
            exclude: ["Info.plist", "SnippetsInfo.plist"])
    ],
    
    swiftLanguageVersions: [
            .v4_2,
            .v5
    ]
)

// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AppManagerSDK",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "AppManagerCore", targets: ["AppManagerCore"]),
        .library(name: "AppManagerLinks", targets: ["AppManagerLinks"]),
        .library(name: "AppManagerGuard", targets: ["AppManagerGuard"]),
        .library(name: "AppManagerPush", targets: ["AppManagerPush"]),
    ],
    targets: [
        .binaryTarget(
            name: "AppManagerCore",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.1/AppManagerCore.xcframework.zip",
            checksum: "73df09bfb1c0a154dfd37c4798d4585d6dc3f136f60872b3abe6dee35ef7be96"
        ),
        .binaryTarget(
            name: "AppManagerLinks",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.1/AppManagerLinks.xcframework.zip",
            checksum: "da2eeee18b4c9da8020ec353d7516aa13ccede0d335d6d5004b0bea870d8c352"
        ),
        .binaryTarget(
            name: "AppManagerGuard",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.1/AppManagerGuard.xcframework.zip",
            checksum: "eee1c9c48e4422dfc9fd235e72b86f0d39397c11417a10a94993a92a7c86988d"
        ),
        .binaryTarget(
            name: "AppManagerPush",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.1/AppManagerPush.xcframework.zip",
            checksum: "54e84a31fd61bb71d93a18b22bca19a9d65dced69facc8030da949173bbf2e64"
        ),
    ]
)

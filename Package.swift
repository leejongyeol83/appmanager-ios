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
        // Binary targets
        .binaryTarget(
            name: "AppManagerCoreBinary",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.2/AppManagerCore.xcframework.zip",
            checksum: "93663e99347bd103e52d9ba50c425c816354a565ad55cc93c30ad2d59c60545c"
        ),
        .binaryTarget(
            name: "AppManagerLinksBinary",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.2/AppManagerLinks.xcframework.zip",
            checksum: "a64f29f222ffa2bfc9d689aa5fcf357b9298a513d55c591066455007de817c96"
        ),
        .binaryTarget(
            name: "AppManagerGuardBinary",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.2/AppManagerGuard.xcframework.zip",
            checksum: "54c8cd69b6ffdc5ba30f175d7797a18da4993da53f5d3cba4d59c8f0bb3c12df"
        ),
        .binaryTarget(
            name: "AppManagerPushBinary",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.2/AppManagerPush.xcframework.zip",
            checksum: "e9ca8742ea0eaed6b99278ffed970df05cd52bc07838e5b8d6b09136096329d7"
        ),
        // Wrapper targets (의존관계 선언)
        .target(
            name: "AppManagerCore",
            dependencies: ["AppManagerCoreBinary"],
            path: "Sources/AppManagerCore"
        ),
        .target(
            name: "AppManagerLinks",
            dependencies: ["AppManagerLinksBinary", "AppManagerCore"],
            path: "Sources/AppManagerLinks"
        ),
        .target(
            name: "AppManagerGuard",
            dependencies: ["AppManagerGuardBinary", "AppManagerCore"],
            path: "Sources/AppManagerGuard"
        ),
        .target(
            name: "AppManagerPush",
            dependencies: ["AppManagerPushBinary", "AppManagerCore"],
            path: "Sources/AppManagerPush"
        ),
    ]
)

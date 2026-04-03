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
        // Binary targets (내부 모듈)
        .binaryTarget(name: "_AppManagerCore",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.4/_AppManagerCore.xcframework.zip",
            checksum: "40c273147da39487fdc9aff03d1c34513537080bbf0fc6655f6ee6daa228d450"),
        .binaryTarget(name: "_AppManagerLinks",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.4/_AppManagerLinks.xcframework.zip",
            checksum: "11ee13411750d035e219d305b69f87f00563ba121f65e4633a618aa0c6430fd1"),
        .binaryTarget(name: "_AppManagerGuard",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.4/_AppManagerGuard.xcframework.zip",
            checksum: "9bda0c01fdf5843d5870b2ddb8827ee2bd6736c7bf6666051eacd26dd7c843f3"),
        .binaryTarget(name: "_AppManagerPush",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.4/_AppManagerPush.xcframework.zip",
            checksum: "005880e939d37693ddd41171f5197eea750d8ba1868351a137924fb8afd1763a"),
        // Wrapper targets (사용자가 import하는 대상)
        .target(name: "AppManagerCore",
            dependencies: ["_AppManagerCore"],
            path: "Sources/AppManagerCore"),
        .target(name: "AppManagerLinks",
            dependencies: ["_AppManagerLinks", "AppManagerCore"],
            path: "Sources/AppManagerLinks"),
        .target(name: "AppManagerGuard",
            dependencies: ["_AppManagerGuard", "AppManagerCore"],
            path: "Sources/AppManagerGuard"),
        .target(name: "AppManagerPush",
            dependencies: ["_AppManagerPush", "AppManagerCore"],
            path: "Sources/AppManagerPush"),
    ]
)

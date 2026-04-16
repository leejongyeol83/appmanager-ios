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
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.1/_AppManagerCore.xcframework.zip",
            checksum: "f13abf634bf4ab057260205ed5efb88e4392e57c62f462747712ceaaed63f234"),
        .binaryTarget(name: "_AppManagerLinks",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.1/_AppManagerLinks.xcframework.zip",
            checksum: "f88c2837ab3cc8eb5432a02955bbf721aa279c222171e5d02f72ff5b5415529c"),
        .binaryTarget(name: "_GuardNative",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.1/_GuardNative.xcframework.zip",
            checksum: "df656739149357fd5ca62befca2623882f0c9f9db3a5bb96c21e22a9b0a0f4eb"),
        .binaryTarget(name: "_AppManagerGuard",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.1/_AppManagerGuard.xcframework.zip",
            checksum: "cd050c60a3f246ea209c2252498fa7e7ec60b09ee13b0ad29daae882781e0db4"),
        .binaryTarget(name: "_AppManagerPush",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.1/_AppManagerPush.xcframework.zip",
            checksum: "d9d099306b79615230a4e633568a3969d36814b785fdba3a18ab370d19e6fccd"),
        // Wrapper targets (사용자가 import하는 대상)
        .target(name: "AppManagerCore",
            dependencies: ["_AppManagerCore"],
            path: "Sources/AppManagerCore"),
        .target(name: "AppManagerLinks",
            dependencies: ["_AppManagerLinks", "AppManagerCore"],
            path: "Sources/AppManagerLinks"),
        .target(name: "AppManagerGuard",
            dependencies: ["_AppManagerGuard", "_GuardNative", "AppManagerCore"],
            path: "Sources/AppManagerGuard"),
        .target(name: "AppManagerPush",
            dependencies: ["_AppManagerPush", "AppManagerCore"],
            path: "Sources/AppManagerPush"),
    ]
)

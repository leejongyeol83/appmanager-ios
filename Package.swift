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
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.2/_AppManagerCore.xcframework.zip",
            checksum: "db70b688892a627e9c038d4803cf4410784e9ec0d6ec2fdae81f7dea8e031179"),
        .binaryTarget(name: "_AppManagerLinks",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.2/_AppManagerLinks.xcframework.zip",
            checksum: "bfb0d8947d68bea7d9156ec938ce354c4f2b15ba6b1023f5ecf6b5adb63eeb62"),
        .binaryTarget(name: "_GuardNative",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.2/_GuardNative.xcframework.zip",
            checksum: "ae6a94e3b0d04637e1d3b8cba3e9042b9c7e13d37c9774161bb7b4738ac8c45d"),
        .binaryTarget(name: "_AppManagerGuard",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.2/_AppManagerGuard.xcframework.zip",
            checksum: "c4d76d268f161b06dc325cb2b514b7842294e9a4a23570c5c80ccc3173a9b5e1"),
        .binaryTarget(name: "_AppManagerPush",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.2/_AppManagerPush.xcframework.zip",
            checksum: "847dce2eab2b99c40be9bf5a2940667756ed917778d822f372124c1dd5bac447"),
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

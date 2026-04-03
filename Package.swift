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
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.5/_AppManagerCore.xcframework.zip",
            checksum: "9d43134e7b5eaa19be54d035863b34332266891b133425d274d31e7eb2bccc2d"),
        .binaryTarget(name: "_AppManagerLinks",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.5/_AppManagerLinks.xcframework.zip",
            checksum: "96c3f353fc6f09657c21a38342b74bb1b52c9a82b7970eb80f5752eaf0c94109"),
        .binaryTarget(name: "_GuardNative",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.5/_GuardNative.xcframework.zip",
            checksum: "47d884cb3180d7642905bffe144b47de42b16963d640c566b90b842c31cd4a98"),
        .binaryTarget(name: "_AppManagerGuard",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.5/_AppManagerGuard.xcframework.zip",
            checksum: "bfad4f2fa94514c09deb0d865d315d039cde9a15a01a8e1c64c0452c8495634d"),
        .binaryTarget(name: "_AppManagerPush",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.5/_AppManagerPush.xcframework.zip",
            checksum: "f5470ef20db1ab7a9ccfdcb25f8c71b553ded57750dae1d913bd361fa5f80afc"),
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

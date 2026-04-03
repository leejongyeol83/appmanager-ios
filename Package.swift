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
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.6/_AppManagerCore.xcframework.zip",
            checksum: "3e194d7b070e1040fee43190b16409f8a40db9d6b427283a58a839bd2ef10e53"),
        .binaryTarget(name: "_AppManagerLinks",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.6/_AppManagerLinks.xcframework.zip",
            checksum: "614ed0f2e6b9916f171f3b3de1a87287faf1fc165f8a1f4b5a382c251b5aa70f"),
        .binaryTarget(name: "_GuardNative",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.6/_GuardNative.xcframework.zip",
            checksum: "8706f1c81c2fc6e8faeb65d2b19f4761a9442d8110727f76526da612525cb304"),
        .binaryTarget(name: "_AppManagerGuard",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.6/_AppManagerGuard.xcframework.zip",
            checksum: "61efe355512e549ce7468e94fa023cefe97dcf51d23e762d1a3fe45a85aaa13f"),
        .binaryTarget(name: "_AppManagerPush",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.6/_AppManagerPush.xcframework.zip",
            checksum: "8632f52a942349d754ddee512fff81eea040d36732810a39d04396dd0a07e30b"),
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

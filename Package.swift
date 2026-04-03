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
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.0/_AppManagerCore.xcframework.zip",
            checksum: "caa686556cb53d42f77c70231f99158dd071af3c9e510ef4dea8974661d592bc"),
        .binaryTarget(name: "_AppManagerLinks",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.0/_AppManagerLinks.xcframework.zip",
            checksum: "190b3780f293776111183032d281e15e10d94add7d2fabd4b01255142f01fd73"),
        .binaryTarget(name: "_GuardNative",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.0/_GuardNative.xcframework.zip",
            checksum: "7814d229a042c57348c648ea0dcb8a6ea4ac7554a889d822606c31ba75bff666"),
        .binaryTarget(name: "_AppManagerGuard",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.0/_AppManagerGuard.xcframework.zip",
            checksum: "7c128721b18a8d5dc93e11919c34b011a8bf01ac07c907df91a396abff7a7abe"),
        .binaryTarget(name: "_AppManagerPush",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.0/_AppManagerPush.xcframework.zip",
            checksum: "24e526a03b33ff9db67ca1ee05981a5c7e00be62be7f469e4943f597deb379b6"),
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

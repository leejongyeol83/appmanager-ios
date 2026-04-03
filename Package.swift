// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AppManagerSDK",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "AppManagerCore", targets: ["AppManagerCore"]),
        .library(name: "AppManagerLinks", targets: ["AppManagerLinks", "AppManagerCore"]),
        .library(name: "AppManagerGuard", targets: ["AppManagerGuard", "AppManagerCore"]),
        .library(name: "AppManagerPush", targets: ["AppManagerPush", "AppManagerCore"]),
    ],
    targets: [
        .binaryTarget(
            name: "AppManagerCore",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.3/AppManagerCore.xcframework.zip",
            checksum: "76cc78e19bddddb9d50a639786cc0e853c197f1adbd806ad2335cff58ed239ec"
        ),
        .binaryTarget(
            name: "AppManagerLinks",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.3/AppManagerLinks.xcframework.zip",
            checksum: "d19dac849745200e608126beec3219360ebba7738783199b8c92fde1feeea0d5"
        ),
        .binaryTarget(
            name: "AppManagerGuard",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.3/AppManagerGuard.xcframework.zip",
            checksum: "a45dee8d7bdcd9aadb808b4e4e317a476254cd6987c355140e28432a10abac9a"
        ),
        .binaryTarget(
            name: "AppManagerPush",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.3/AppManagerPush.xcframework.zip",
            checksum: "a5630bf452d7735be611ab2ad85776a7272f9e7dd3c0df663571ad474a6469ab"
        ),
    ]
)

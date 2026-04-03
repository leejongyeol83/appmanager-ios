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
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.0/AppManagerCore.xcframework.zip",
            checksum: "211f635ea2ad2b2d2faae7f4b6061ada8c3f53967b07fd8ea4cc2ba6953433af"
        ),
        .binaryTarget(
            name: "AppManagerLinks",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.0/AppManagerLinks.xcframework.zip",
            checksum: "f74fb9c96c8e0ff8c70c5117ac59f467b74b9dc86f2410fb3200d2f9d32f7b04"
        ),
        .binaryTarget(
            name: "AppManagerGuard",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.0/AppManagerGuard.xcframework.zip",
            checksum: "83cfa3a1e3ac2b8bad865898870331175d409b97aba504b71e7ebe553b9cfa3e"
        ),
        .binaryTarget(
            name: "AppManagerPush",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.0/AppManagerPush.xcframework.zip",
            checksum: "8b09361ef2e2503c4bd23ad5569c9e9d600f7ce8cadfc2bb9755ee4bbc73d193"
        ),
    ]
)

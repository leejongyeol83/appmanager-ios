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
            checksum: "20d159210b7452ef294edb41feb6830f9a67b30f9393e025edbda66797c71beb"
        ),
        .binaryTarget(
            name: "AppManagerLinks",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.0/AppManagerLinks.xcframework.zip",
            checksum: "4c7b352d24944cf7d43ca307d3ddf5e4936810ccbe3e0c39e055b6f3b7348573"
        ),
        .binaryTarget(
            name: "AppManagerGuard",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.0/AppManagerGuard.xcframework.zip",
            checksum: "fd5379d0aec7ef7eaf92ed65fa62dc879d0395c325aa22bce8fa7b07ba17375e"
        ),
        .binaryTarget(
            name: "AppManagerPush",
            url: "https://github.com/leejongyeol83/appmanager-ios/releases/download/v1.0.0/AppManagerPush.xcframework.zip",
            checksum: "9ca84c9d8b77fc53a7568a9b87882ec20a274dd830fa8594e81fb24787b9d32c"
        ),
    ]
)

// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "nb_maps_flutter",
    platforms: [
        .iOS("12.0")
    ],
    products: [
        .library(name: "nb-maps-flutter", targets: ["nb_maps_flutter"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(
            url: "https://github.com/nextbillion-ai/maps-native-distribution",
            exact: "2.3.3"
        )
    ],
    targets: [
        .target(
            name: "nb_maps_flutter",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "Nbmap", package: "maps-native-distribution")
            ],
            resources: [.process("PrivacyInfo.xcprivacy")]
        )
    ]
)

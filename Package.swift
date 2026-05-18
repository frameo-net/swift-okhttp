// swift-tools-version: 6.2

import Foundation
import PackageDescription

let package = Package(
    name: "swift-okhttp",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .watchOS(.v11),
        .tvOS(.v18),
    ],
    products: [
        .library(
            name: "OpenAPIOkHttp",
            targets: ["OpenAPIOkHttp"]
        ),
        .library(name: "OkHttp", targets: ["OkHttp"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-java", from: "0.3.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.11.0", traits: [])
    ],
    targets: [
        .target(
            name: "OpenAPIOkHttp",
            dependencies: [
                "OkHttp",
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime")
            ]
        ),
        .target(
            name: "OkHttp",
            dependencies: [
                .product(name: "SwiftJava", package: "swift-java"),
                .product(name: "JavaIO", package: "swift-java"),
                .product(name: "JavaUtil", package: "swift-java"),
            ],
            exclude: ["swift-java.config"],
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ]
        ),
        .testTarget(
            name: "OpenAPIOkHttpTests",
            dependencies: ["OpenAPIOkHttp"]
        ),
    ]
)

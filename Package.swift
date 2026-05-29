// swift-tools-version: 6.2

import Foundation
import PackageDescription

let package = Package(
    name: "swift-okhttp",
    // OkHttp runs through a JVM via JNI, so the only supported platforms are
    // those that can host a JVM: macOS and Linux. (Linux needs no explicit
    // platform declaration here.) Apple's mobile/embedded platforms cannot run
    // a JVM and are intentionally unsupported.
    platforms: [
        .macOS(.v15)
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

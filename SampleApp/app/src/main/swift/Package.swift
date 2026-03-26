// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SampleLib",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "SampleLib",
            type: .dynamic,
            targets: ["SampleLib"]
        )
    ],
    dependencies: [
        .package(name: "swift-okhttp", path: "../../../../../"),
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.6.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.11.0"),
        .package(url: "https://github.com/swiftlang/swift-java", branch: "main"),
    ],
    targets: [
        .target(
            name: "SampleLib",
            dependencies: [
                .product(name: "OpenAPIOkHttp", package: "swift-okhttp"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "SwiftJava", package: "swift-java"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ],
            plugins: [
                .plugin(name: "JExtractSwiftPlugin", package: "swift-java"),
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator"),
            ],
        )
    ]
)

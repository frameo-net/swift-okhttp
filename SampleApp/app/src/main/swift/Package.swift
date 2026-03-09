// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SampleLib",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SampleLib",
            type: .dynamic,
            targets: ["SampleLib"]
        ),
    ],
    dependencies: [
        .package(name: "swift-openapi-okhttp", path: "../../../../../"),
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.6.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.11.0"),
        .package(url: "https://github.com/swiftlang/swift-java", branch: "main")
    ],
    targets: [
        .target(
            name: "SampleLib",
            dependencies: [
                .product(name: "OpenAPIOkHttp", package: "swift-openapi-okhttp"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "SwiftJava", package: "swift-java"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ],
            plugins: [
                .plugin(name: "JExtractSwiftPlugin", package: "swift-java"),
                .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator"),
            ],
        ),
    ]
)

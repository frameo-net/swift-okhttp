# swift-okhttp

Swift bindings for [OkHttp](https://github.com/square/okhttp), generated with
[swift-java](https://github.com/swiftlang/swift-java), plus an
[`OpenAPIOkHttp`](Sources/OpenAPIOkHttp) transport implementing
[`ClientTransport`](https://github.com/apple/swift-openapi-runtime) for
[Swift OpenAPI](https://github.com/apple/swift-openapi-generator).

It lets Swift code use OkHttp as its HTTP client. The primary motivation is
**Swift on Android**: there is no `URLSession`, and Foundation's networking
support is limited, but OkHttp is the de-facto HTTP client already present on
Android. This package gives Swift-on-Android code a robust, idiomatic HTTP
client by bridging directly to OkHttp.

It also works on any other host with a Java runtime (e.g. desktop/server JVM on
macOS or Linux), which is how the [`SampleApp`](SampleApp) runs.

> [!IMPORTANT]
> **OkHttp is a Java library.** This package calls into it over JNI (via
> swift-java), so it needs a Java runtime and the OkHttp classes available at
> runtime. On Android both are already part of the app (the ART runtime plus
> OkHttp as a normal Gradle dependency); your Swift code is compiled to native
> and loaded into the app process. This is not a pure-Swift, standalone HTTP
> client. See [Requirements](#requirements) and [How it works](#how-it-works).

## Requirements

- Swift 6.2+
- A Java runtime with OkHttp `4.12.0` on the classpath:
  - **Android** — the primary target; OkHttp ships as a standard `implementation` dependency.
  - **Desktop/server JVM** — a JDK (the [`SampleApp`](SampleApp) targets JDK 21) with OkHttp on the classpath.
- iOS, watchOS, and tvOS are **not** supported — they cannot host a Java runtime.
  (The SwiftPM `platforms` list only declares macOS; Android is built via the
  Swift Android cross-compilation toolchain rather than a `platforms` entry.)

## Products

- **`OkHttp`** — generated Swift wrappers over the OkHttp API.
- **`OpenAPIOkHttp`** — `OkHttpClientTransport`, a `ClientTransport` for
  swift-openapi-runtime backed by OkHttp.

## Installation

```swift
.package(url: "https://github.com/madsodgaard/swift-okhttp", from: "0.1.0")
```

```swift
.target(
    name: "MyTarget",
    dependencies: [
        .product(name: "OpenAPIOkHttp", package: "swift-okhttp"),
        // or .product(name: "OkHttp", package: "swift-okhttp")
    ]
)
```

## Usage

Using the OpenAPI transport:

```swift
import OkHttp
import OpenAPIOkHttp

let client = OkHttpClient()
let transport = OkHttpClientTransport(
    configuration: .init(client: client)
)
let apiClient = try Client(serverURL: Servers.Server1.url(), transport: transport)
let response = try await apiClient.getRequest()
```

See [`SampleApp`](SampleApp) for a complete, runnable example, including the
Gradle wiring that loads the compiled Swift dynamic library into a JVM and puts
OkHttp on the classpath.

## How it works

swift-java generates Swift wrappers for OkHttp's Java classes and bridges calls
over JNI. At runtime the Swift code runs inside a Java runtime that has OkHttp
on its classpath.

On **Android**, that runtime is the app's ART process: your Swift code is
cross-compiled to a native library and loaded into the app, and OkHttp is
already available as a normal Gradle dependency — so there is nothing extra to
ship.

The [`SampleApp`](SampleApp) demonstrates the same mechanism on a desktop JVM:
the Swift package is built as a dynamic library, loaded with
`System.loadLibrary(...)` from a Java entry point, with OkHttp supplied as a
normal JVM dependency.

## Regenerating the wrappers

The Swift wrappers in `Sources/OkHttp` are committed and checked in. To
regenerate them (e.g. to bump the OkHttp version in `Sources/OkHttp/swift-java.config`):

```bash
./scripts/generate-wrappers.sh
```

This resolves the classpath and runs `swift-java wrap-java`. Note the script
includes a post-processing step that removes a duplicate `close()` declaration.

## License

swift-okhttp is released under the [MIT License](LICENSE). It wraps and depends
on third-party software under their own licenses — see [NOTICE.md](NOTICE.md)
for OkHttp (Apache 2.0), swift-java, and swift-openapi-runtime attributions.

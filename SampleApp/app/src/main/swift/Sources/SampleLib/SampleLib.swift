// The Swift Programming Language
// https://docs.swift.org/swift-book

import OkHttp
import OpenAPIOkHttp

public func run() async {
    do {
        let okHttpClient = OkHttpClient()
        let transport = OkHttpClientTransport(client: okHttpClient)
        let client = try Client(serverURL: Servers.Server1.url(), transport: transport)
        _ = try await client.getRequest().ok.body
        print("Response successful!")
    } catch {
        print("Failed with \(error)")
    }
}

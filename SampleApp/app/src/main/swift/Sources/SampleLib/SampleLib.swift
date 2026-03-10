// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import OkHttp
import OpenAPIOkHttp

public func run() async {
    do {
        let okHttpClient = OkHttpClient()
        let configuration = OkHttpClientTransport.Configuration(client: okHttpClient)
        let transport = OkHttpClientTransport(configuration: configuration)
        let client = try Client(serverURL: Servers.Server1.url(), transport: transport)
        _ = try await client.getRequest().ok.body.json
        print("Response successful!")
        fflush(stdout)
    } catch {
        print("Failed with \(error)")
        fflush(stdout)
    }
}

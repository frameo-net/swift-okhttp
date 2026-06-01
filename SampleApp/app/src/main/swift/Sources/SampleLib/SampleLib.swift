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
        // Let CI / tests point the sample at a local mock server so end-to-end
        // runs don't depend on an external host being reachable. Falls back to
        // the server URL baked into the OpenAPI document.
        let serverURL: URL
        if let override = ProcessInfo.processInfo.environment["SAMPLE_SERVER_URL"],
            let overrideURL = URL(string: override)
        {
            serverURL = overrideURL
        } else {
            serverURL = try Servers.Server1.url()
        }
        let client = try Client(serverURL: serverURL, transport: transport)
        _ = try await client.getRequest().ok.body.json
        print("Response successful!")
        fflush(stdout)
    } catch {
        print("Failed with \(error)")
        fflush(stdout)
    }
}

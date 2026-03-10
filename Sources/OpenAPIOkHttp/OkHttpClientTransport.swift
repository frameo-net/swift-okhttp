// The Swift Programming Language
// https://docs.swift.org/swift-book

import Dispatch
import HTTPTypes
@preconcurrency import OkHttp
import OpenAPIRuntime
import SwiftJava

#if canImport(FoundationEssentials)
    import FoundationEssentials
#else
    import Foundation
#endif

public struct OkHttpClientTransport: ClientTransport {

    /// A set of configuration values for the OkHttp transport.
    public struct Configuration: Sendable {
        /// The OkHttp client used to perform HTTP operations.
        public let client: OkHttpClient

        public init(client: OkHttpClient = OkHttpClient()) {
            self.client = client
        }
    }

    /// A dispatch queue used to run network requests on, to prevent blocking Swift Concurrency's thread pool.
    private let dispatchQueue = DispatchQueue(
        label: "com.madsodgaard.swift-openapi-client.okhttp-client-transport",
        attributes: .concurrent
    )

    /// A set of configuration values used by the transport.
    public var configuration: Configuration

    /// Creates a new URLSession-based transport.
    /// - Parameter configuration: A set of configuration values used by the transport.
    public init(configuration: Configuration = .init()) { self.configuration = configuration }

    public func send(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        let httpRequest = try await Self.convertRequest(request, body: body, baseURL: baseURL)
        let call = self.configuration.client.newCall(httpRequest)
        return try await withTaskCancellationHandler {
            return try await withCheckedThrowingContinuation { continuation in
                dispatchQueue.async {
                    do {
                        guard let response = try self.configuration.client.newCall(httpRequest).execute() else {
                            continuation.resume(throwing: Error.javaNilError)
                            return
                        }

                        let result = try Self.convertResponse(method: request.method, httpResponse: response)
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        } onCancel: {
            call?.cancel()
        }
    }

    // MARK: Internal

    /// Specialized error thrown by the transport.
    enum Error: Swift.Error, CustomStringConvertible, LocalizedError {

        /// Invalid URL composed from base URL and received request.
        case invalidRequestURL(request: HTTPRequest, baseURL: URL)

        /// An object returned by Java was unexpectedly nil
        case javaNilError

        // MARK: CustomStringConvertible

        var description: String {
            switch self {
            case .invalidRequestURL(let request, let baseURL):
                return
                    "Invalid request URL from request path: \(request.path ?? "<nil>") relative to base URL: \(baseURL.absoluteString)"
            case .javaNilError:
                return "An object returned by Java was nil"
            }
        }

        // MARK: LocalizedError

        var errorDescription: String? { description }
    }

    /// Converts the shared Request type into URLRequest.
    static func convertRequest(_ request: HTTPRequest, body: HTTPBody?, baseURL: URL) async throws -> Request {
        guard var baseUrlComponents = URLComponents(string: baseURL.absoluteString),
            let requestUrlComponents = URLComponents(string: request.path ?? "")
        else { throw Error.invalidRequestURL(request: request, baseURL: baseURL) }
        baseUrlComponents.percentEncodedPath += requestUrlComponents.percentEncodedPath
        baseUrlComponents.percentEncodedQuery = requestUrlComponents.percentEncodedQuery
        guard let url = baseUrlComponents.url else { throw Error.invalidRequestURL(request: request, baseURL: baseURL) }

        var requestBuilder = Request.Builder()
            .url(url.absoluteString)

        for header in request.headerFields {
            requestBuilder = requestBuilder?.addHeader(header.name.canonicalName, header.value)
        }

        var requestBody: RequestBody? = nil
        if let body {
            let bytes = try await Array(collecting: body, upTo: .max)
            // TODO: Is this force-cast safe?
            requestBody = try JavaClass<RequestBody>().create(bytes as! [Int8])
        }

        requestBuilder = requestBuilder?.method(request.method.rawValue, requestBody)

        return requestBuilder!.build()
    }

    /// Converts the received URLResponse into the shared Response.
    static func convertResponse(method: HTTPRequest.Method, httpResponse: Response) throws -> (
        HTTPResponse, HTTPBody?
    ) {
        var headerFields: HTTPFields = [:]
        let headers = httpResponse.headers()!
        for i in 0..<headers.size() {
            let headerName = headers.name(i)
            let headerValue = headers.value(i)
            headerFields[.init(headerName)!] = headerValue
        }

        var body: HTTPBody?
        switch method {
        case .head, .connect, .trace: body = nil
        default:
            let bytes = try httpResponse.body().bytes()
            bytes.withUnsafeBufferPointer { buffer in
                buffer.withMemoryRebound(to: UInt8.self) { buffer in
                    // Unfortunate copy...
                    body = HTTPBody([UInt8](buffer))
                }
            }
        }

        let response = HTTPResponse(status: .init(code: Int(httpResponse.code())), headerFields: headerFields)
        return (response, body)
    }
}

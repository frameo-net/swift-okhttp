// The Swift Programming Language
// https://docs.swift.org/swift-book

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
    private let client: OkHttpClient

    public init(client: OkHttpClient) {
        self.client = client
    }

    public func send(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        let httpRequest = try await Self.convertRequest(request, body: body, baseURL: baseURL)
        let response = try await withCheckedThrowingContinuation { continuation in
            let callback = ResponseHandlerStore.shared.save { (response, exception) in
                if let response {
                    continuation.resume(returning: response)
                } else if let exception {
                    continuation.resume(throwing: exception)
                } else {
//                    continuation.resume(throwing: JavaNilError.self)
                }
            }
            client.newCall(httpRequest).enqueue(callback)
        }
        return try Self.convertResponse(method: request.method, httpResponse: response)
    }

    // MARK: Internal

    /// Specialized error thrown by the transport.
    internal enum Error: Swift.Error, CustomStringConvertible, LocalizedError {

        /// Invalid URL composed from base URL and received request.
        case invalidRequestURL(request: HTTPRequest, baseURL: URL)

        case networkError(String)

        // MARK: CustomStringConvertible

        var description: String {
            switch self {
            case .invalidRequestURL(let request, let baseURL):
                return "Invalid request URL from request path: \(request.path ?? "<nil>") relative to base URL: \(baseURL.absoluteString)"
            case .networkError(let message):
                return "Network error: \(message)"
            }
        }

        // MARK: LocalizedError

        var errorDescription: String? { description }
    }

    /// Converts the shared Request type into URLRequest.
    internal static func convertRequest(_ request: HTTPRequest, body: HTTPBody?, baseURL: URL) async throws -> Request {
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
            requestBody = try JavaClass<RequestBody>().create(bytes.map { Int8(bitPattern: $0) })
        }

        requestBuilder = requestBuilder?.method(request.method.rawValue, requestBody)

        return requestBuilder!.build()
    }

    /// Converts the received URLResponse into the shared Response.
    internal static func convertResponse(method: HTTPRequest.Method, httpResponse: Response) throws -> (
        HTTPResponse, HTTPBody?
    ) {
        var headerFields: HTTPFields = [:]
        let headers = httpResponse.headers()!
        for i in 0..<headers.size() {
            let headerName = headers.name(i)
            let headerValue = headers.value(i)
            headerFields[.init(headerName)!] = headerValue
        }

        let length: HTTPBody.Length
        if let lengthHeaderString = headerFields[.contentLength], let lengthHeader = Int64(lengthHeaderString) {
            length = .known(lengthHeader)
        } else {
            length = .unknown
        }

        let body: HTTPBody?
        switch method {
        case .head, .connect, .trace: body = nil
        default:
            body = HTTPBody(
                AsyncThrowingStream { continuation in
                    let inputStream = httpResponse.body().byteStream()
                    var buffer = [Int8](repeating: 0, count: 8192)
                    do {
                        while let bytesRead = try inputStream?.read(buffer), bytesRead > 0 {
                            print("read buffer: \(bytesRead)")
                            fflush(stdout)
                            continuation.yield(buffer.map(UInt8.init(bitPattern:))[..<Int(bytesRead)])
                            buffer.removeAll(keepingCapacity: true)
                        }
                    } catch {
                        continuation.finish(throwing: error)
                    }
                    continuation.finish()
                },
                length: length
            )
        }

        let response = HTTPResponse(status: .init(code: Int(httpResponse.code())), headerFields: headerFields)
        return (response, body)
    }
}

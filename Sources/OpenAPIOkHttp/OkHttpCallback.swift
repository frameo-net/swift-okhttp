import Foundation
import HTTPTypes
@preconcurrency import OkHttp
import OpenAPIRuntime
import SwiftJava

@JavaClass("com.madsodgaard.swiftopenapiokhttp.OkHttpCallback", implements: Callback.self)
open class OkHttpCallback: JavaObject {
    @JavaMethod
    func getIdentifier() -> Int64

    @JavaMethod
    @_nonoverride public convenience init(_ arg0: Int64, environment: JNIEnvironment? = nil)
}

@JavaImplementation("com.madsodgaard.swiftopenapiokhttp.OkHttpCallback")
extension OkHttpCallback {
    @JavaMethod
    func onFailure(exception: Exception?) {
        if let handler = ResponseHandlerStore.shared.remove(forId: self.getIdentifier()) {
            handler((nil, exception))
        }
    }

    @JavaMethod
    func nativeOnResponse(response: Response?) {
        if let handler = ResponseHandlerStore.shared.remove(forId: self.getIdentifier()) {
            handler((response, nil))
        }
    }
}

import Synchronization
import OkHttp
import SwiftJava

typealias ResponseHandler = @Sendable ((Response?, Exception?)) -> Void

final class ResponseHandlerStore: @unchecked Sendable {
    private let store = Mutex<[Int64: ResponseHandler]>([:])
    private init() {}

    static let shared = ResponseHandlerStore()

    func save(_ body: @escaping ResponseHandler) -> Callback {
        let id = Int64.random(in: Int64.min...Int64.max)
        self.store.withLock { store in
            store[id] = body
        }
        let callback = OkHttpCallback(id)
        return callback.as(Callback.self)!
    }

    func remove(forId id: Int64) -> ResponseHandler? {
        self.store.withLock { store in
            return store.removeValue(forKey: id)
        }
    }
}

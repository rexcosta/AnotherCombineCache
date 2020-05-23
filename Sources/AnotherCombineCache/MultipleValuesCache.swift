//
// The MIT License (MIT)
//
// Copyright (c) 2020 Effective Like ABoss, David Costa Gonçalves
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import AnotherSwiftCommonLib
import Combine
import Foundation
import os

/// MultipleValuesCache is used to cache a single value for a given key produced from a given producer
/// While a value is produced, other value requesters will not trigger another produce action for a given key
/// If the value don't exists or a error occurred the producer will be used to obtain the value/failure
/// - Key: key to associate the fetched data for a given key
/// - Value: the type of the cached value
/// - Failure: The error type that can be produced
/// MultipleValuesCache is thread safe
public final class MultipleValuesCache<Key: Hashable, Value, Failure: Error> {
    
    /// Describes the internal state for the a MultipleValuesCache value
    private enum State {
        case error(_ error: Failure)
        case value(_ value: Value)
        case refreshing(_ downstream: PassthroughSubject<Value, Failure>)
    }
    
    private var cacheAccessLock = NSRecursiveLock()
    private var cache = [Key: State]()
    
    private let producer: (_ key: Key) -> AnyPublisher<Value, Failure>
    private var cancellables = Set<AnyCancellable>()
    
    private let log: OSLog
    public let cacheName: String
    
    /// Creates a ready to use ValueCache
    /// - Parameters:
    ///   - log: the OSLog to be used, `default` to OSLog.default
    ///   - valueCacheName: the name to appear in the logs, `default`to  empty string
    ///   - producer: the upstream data producer to be consumed by ValueCache
    public init(
        log: OSLog = .default,
        cacheName: String = "",
        producer: @escaping (_ key: Key) -> AnyPublisher<Value, Failure>
    ) {
        self.log = log
        self.cacheName = cacheName
        self.producer = producer
    }
    
    /// Loads the value if needed or try to produce a value and save's it for the given key
    /// - If the value don't exist or any error occurred previously, this method will use the producer to produce a value
    /// - If the value already exists, the value will be returned
    /// - If the value is already being queried this do nothing
    /// - Parameter key: the key used to produce a value or to fetch the value already produced
    /// - Returns: Publisher to subscribe for value/failure update
    public func value(for key: Key) -> AnyPublisher<Value, Failure> {
        cacheAccessLock.lock()
        defer {
            cacheAccessLock.unlock()
        }
        
        guard let value = cache[key] else {
            return create(for: key)
        }
        
        switch value {
        case .error:
            return create(for: key)
            
        case .value(let theValue):
            return Result.makeSuccess(theValue)
            
        case .refreshing(let downstream):
            return downstream.eraseToAnyPublisher()
        }
    }
    
}

// MARK: Private
extension MultipleValuesCache {
    
    private func create(for key: Key) -> AnyPublisher<Value, Failure> {
        os_log(.debug, log: log, "[%s] Refreshing Value for key %s", cacheName, String(describing: key))
        
        let downstream = PassthroughSubject<Value, Failure>()
        cache[key] = .refreshing(downstream)
        produce(for: key, downstream)
        return downstream.eraseToAnyPublisher()
    }
    
    private func produce(for key: Key, _ downstream: PassthroughSubject<Value, Failure>) {
        let producer = Deferred {
            return self.producer(key)
        }
        
        producer.sinkIntoResultAndStore(in: &cancellables) { [weak self] (result) in
            switch result {
                
            case .success(let data):
                if let this = self {
                    os_log(.debug, log: this.log, "[%s] Produce with Success for key %s", this.cacheName, String(describing: key))
                    
                    this.cacheAccessLock.lock()
                    this.cache[key] = .value(data)
                    this.cacheAccessLock.unlock()
                }
                downstream.send(data)
                downstream.send(completion: .finished)
                
            case .failure(let error):
                if let this = self {
                    os_log(.error, log: this.log, "[%s] Produce with Error %s for key %s",
                           this.cacheName,
                           error.localizedDescription,
                           String(describing: key))
                    
                    this.cacheAccessLock.lock()
                    this.cache[key] = .error(error)
                    this.cacheAccessLock.unlock()
                }
                downstream.send(completion: .failure(error))
            }
        }
    }
    
}

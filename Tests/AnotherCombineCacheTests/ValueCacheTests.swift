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

import Combine
import XCTest
@testable import AnotherCombineCache

final class ValueCacheTests: XCTestCase {
    
    func testNormalUse() {
        var cancellables = Set<AnyCancellable>()
        let queue = DispatchQueue(label: "DispatchQueue")
        var path = [Int]()
        
        let cache = ValueCache<Int, Never>(cacheName: "int") { () -> AnyPublisher<Int, Never> in
            return Future { promisse in
                queue.asyncAfter(deadline: .now() + 5) {
                    promisse(Result.success(1))
                }
            }.eraseToAnyPublisher()
        }
        
        var expectations = [XCTestExpectation]()
        for index in 1...5 {
            let expectation = XCTestExpectation(description: "Expectation \(index)")
            expectations.append(expectation)
            
            cache.value().sinkIntoResultAndStore(in: &cancellables) { result in
                switch result {
                case .success(let value):
                    path.append(value)
                    expectation.fulfill()
                }
            }
        }
        
        let expectedResult = [1, 1, 1, 1, 1]
        wait(for: expectations, timeout: 30)
        
        XCTAssertEqual(expectedResult, path)
    }
    
    func testPreload() {
        var cancellables = Set<AnyCancellable>()
        let queue = DispatchQueue(label: "DispatchQueue")
        var path = [Int]()
        
        let cache = ValueCache<Int, Never>(cacheName: "int") { () -> AnyPublisher<Int, Never> in
            return Future { promisse in
                queue.asyncAfter(deadline: .now() + 5) {
                    promisse(Result.success(1))
                }
            }.eraseToAnyPublisher()
        }
        
        cache.preload()
        
        var expectations = [XCTestExpectation]()
        for index in 1...5 {
            let expectation = XCTestExpectation(description: "Expectation \(index)")
            expectations.append(expectation)
            
            cache.value().sinkIntoResultAndStore(in: &cancellables) { result in
                switch result {
                case .success(let value):
                    path.append(value)
                    expectation.fulfill()
                }
            }
        }
        
        let expectedResult = [1, 1, 1, 1, 1]
        wait(for: expectations, timeout: 30)
        
        XCTAssertEqual(expectedResult, path)
    }

    static var allTests = [
        ("testNormalUse", testNormalUse),
        ("testPreload", testPreload),
    ]
    
}

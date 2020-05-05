import XCTest
import ReactiveSwift
import Hydra


func asyncTest(on testCase: XCTestCase, _ block: () throws -> Hydra.Promise<Void>) rethrows {
    let expectation = testCase.expectation(description: String(reflecting: testCase))

    try block()
        .catch { error in XCTFail("\(error)") }
        .always { expectation.fulfill() }

    testCase.waitForExpectations(timeout: 3)
}

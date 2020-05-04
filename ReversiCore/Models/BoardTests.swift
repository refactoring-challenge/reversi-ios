import XCTest
import MirrorDiffKit
@testable import ReversiCore



class BoardTests: XCTestCase {
    func testAvailability() {
        struct TestCase {
            let board: Board
            let turn: Turn
            let expected: Set<Coordinate>
        }



        let testCases: [UInt: TestCase] = [
            #line: TestCase(
                board: Board(unsafeArray: [
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, .light, .dark, nil, nil, nil],
                    [nil, nil, nil, .dark, .light, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                ]),
                turn: .first,
                expected: Set([
                    Coordinate(x: .e, y: .six),
                    Coordinate(x: .c, y: .four),
                    Coordinate(x: .d, y: .three),
                    Coordinate(x: .f, y: .five),
                ])
            ),
            #line: TestCase(
                // XXX: This is not reachable board, but a good example to test board ends.
                board: Board(unsafeArray: [
                    [nil, .light, .dark, nil, nil, nil, nil, nil],
                    [nil, nil, .dark, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                ]),
                turn: .first,
                expected: Set([
                    Coordinate(x: .a, y: .one),
                ])
            ),
            #line: TestCase(
                // XXX: This is not reachable board, but a good example to test no available coordinates.
                board: Board(unsafeArray: [
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, .light, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                ]),
                turn: .first,
                expected: Set()
            ),
            // SEE: Fig.6 of https://ja.wikipedia.org/wiki/%E3%82%AA%E3%82%BB%E3%83%AD_(%E3%83%9C%E3%83%BC%E3%83%89%E3%82%B2%E3%83%BC%E3%83%A0)#%E5%9F%BA%E6%9C%AC%E3%83%AB%E3%83%BC%E3%83%AB
            #line: TestCase(
                board: Board(unsafeArray: [
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, .dark, .dark, .dark, nil, nil, .light],
                    [nil, nil, nil, .dark, .dark, .dark, .light, .light],
                    [nil, nil, nil, nil, nil, .dark, nil, .light],
                    [nil, nil, nil, nil, nil, .dark, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                ]),
                turn: .first,
                expected: Set()
            ),
        ]

        testCases.forEach {
            let (line, testCase) = $0

            let actual = Set(testCase.board.availableCoordinates(for: testCase.turn))
            XCTAssertEqual(actual, testCase.expected, diff(between: testCase.expected, and: actual), line: line)
        }
    }
}

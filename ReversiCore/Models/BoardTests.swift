import XCTest
import MirrorDiffKit
@testable import ReversiCore



class BoardTests: XCTestCase {
    func testAvailability() {
        struct TestCase {
            let board: Board<Disk?>
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
        ]

        testCases.forEach {
            let (line, testCase) = $0

            let actual = Set(testCase.board.availableCoordinates(for: testCase.turn))
            XCTAssertEqual(actual, testCase.expected, diff(between: testCase.expected, and: actual), line: line)
        }
    }
}

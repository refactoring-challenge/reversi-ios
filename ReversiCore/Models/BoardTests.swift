import XCTest
import MirrorDiffKit
@testable import ReversiCore



class BoardTests: XCTestCase {
    func testAvailability() {
        struct TestCase {
            let board: Board<Disk?>
            let diskToTest: Disk
            let expected: Set<Line>
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
                diskToTest: .light,
                expected: Set([
                    Line(
                        start: Coordinate(x: .four, y: .four),
                        unsafeEnd: Coordinate(x: .four, y: .six),
                        directedDistance: DirectedDistance(direction: .bottom, distance: .two)
                    ),
                    Line(
                        start: Coordinate(x: .four, y: .four),
                        unsafeEnd: Coordinate(x: .six, y: .four),
                        directedDistance: DirectedDistance(direction: .right, distance: .two)
                    ),
                    Line(
                        start: Coordinate(x: .five, y: .five),
                        unsafeEnd: Coordinate(x: .five, y: .three),
                        directedDistance: DirectedDistance(direction: .top, distance: .two)
                    ),
                    Line(
                        start: Coordinate(x: .five, y: .five),
                        unsafeEnd: Coordinate(x: .three, y: .five),
                        directedDistance: DirectedDistance(direction: .left, distance: .two)
                    ),
                ])
            ),
            #line: TestCase(
                board: Board(unsafeArray: [
                    [nil, .dark, .light, nil, nil, nil, nil, nil],
                    [nil, nil, .light, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                    [nil, nil, nil, nil, nil, nil, nil, nil],
                ]),
                diskToTest: .light,
                expected: Set([
                    Line(
                        start: Coordinate(x: .three, y: .one),
                        unsafeEnd: Coordinate(x: .one, y: .one),
                        directedDistance: DirectedDistance(direction: .left, distance: .two)
                    ),
                ])
            ),
        ]

        testCases.forEach {
            let (line, testCase) = $0

            let actual = Set(testCase.board.availableCoordinates(for: testCase.diskToTest))
            XCTAssertEqual(actual, testCase.expected, diff(between: testCase.expected, and: actual), line: line)
        }
    }
}
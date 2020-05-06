import XCTest
import MirrorDiffKit
import ReversiCore


class FlippableLineTests: XCTestCase {
    func testValidate() {
        struct TestCase {
            let turn: Turn
            let lineContents: LineContents
            let expected: FlippableLine.ValidationResult
        }


        let testCases: [UInt: TestCase] = [
            #line: TestCase(
                turn: .first,
                lineContents: LineContents(
                    board: Board(unsafeArray: [
                        [nil, .light, .dark, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                    ]),
                    line: Line(
                        start: Coordinate(x: .c, y: .one),
                        directedDistance: DirectedDistance(direction: .left, distance: .two)
                    )!
                ),
                expected: .available(FlippableLine(
                    line: Line(
                        start: Coordinate(x: .c, y: .one),
                        directedDistance: DirectedDistance(direction: .left, distance: .two)
                    )!,
                    unsafeFirstEntry: .init(unsafeDisk: .dark, at: Coordinate(x: .c, y: .one)),
                    unsafeMiddleEntries: NonEmptyArray(first: .init(unsafeDisk: .light, at: Coordinate(x: .b, y: .one))),
                    unsafeLastEntry: .init(unsafeDisk: nil, at: Coordinate(x: .a, y: .one))
                ))
            ),
            #line: TestCase(
                turn: .first,
                lineContents: LineContents(
                    board: Board(unsafeArray: [
                        [.light, .light, .dark, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                    ]),
                    line: Line(
                        start: Coordinate(x: .c, y: .one),
                        directedDistance: DirectedDistance(direction: .left, distance: .two)
                    )!
                ),
                expected: .unavailable(because: .endIsNotEmpty)
            ),
            #line: TestCase(
                turn: .first,
                lineContents: LineContents(
                    board: Board(unsafeArray: [
                        [.light, .light, .light, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                    ]),
                    line: Line(
                        start: Coordinate(x: .c, y: .one),
                        directedDistance: DirectedDistance(direction: .left, distance: .two)
                    )!
                ),
                expected: .unavailable(because: .startIsNotSameColor)
            ),
            #line: TestCase(
                turn: .first,
                lineContents: LineContents(
                    board: Board(unsafeArray: [
                        [nil, .dark, .dark, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                    ]),
                    line: Line(
                        start: Coordinate(x: .c, y: .one),
                        directedDistance: DirectedDistance(direction: .left, distance: .two)
                    )!
                ),
                expected: .unavailable(because: .disksOnLineIncludingEmptyOrSameColor)
            ),
            #line: TestCase(
                turn: .first,
                lineContents: LineContents(
                    board: Board(unsafeArray: [
                        [nil, .dark, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                    ]),
                    line: Line(
                        start: Coordinate(x: .b, y: .one),
                        directedDistance: DirectedDistance(direction: .left, distance: .one)
                    )!
                ),
                expected: .unavailable(because: .lineIsTooShort)
            ),
        ]

        testCases.forEach {
            let (line, testCase) = $0

            let actual = FlippableLine.validate(
                lineContents: testCase.lineContents,
                turn: testCase.turn
            )
            XCTAssertEqual(actual, testCase.expected, diff(between: testCase.expected, and: actual), line: line)
        }
    }
}

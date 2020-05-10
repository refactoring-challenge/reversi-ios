import XCTest
import MirrorDiffKit
import ReversiCore



class BoardAnimationModelTests: XCTestCase {
    func testNext() {
        struct TestCase {
            let start: BoardAnimationModelState
            let expectedHistoryUntilNotAnimating: [BoardAnimationModelState]
        }



        let testCases: [UInt: TestCase] = [
            #line: TestCase(
                start: .placing(
                    at: Coordinate(x: .a, y: .one),
                    with: .dark,
                    restLines: NonEmptyArray([
                        FlippableLine(
                            line: Line(
                                start: Coordinate(x: .c, y: .one),
                                directedDistance: DirectedDistance(direction: .left, distance: .two)
                            )!,
                            unsafeFirstEntry: FlippableLine.Entry(unsafeDisk: .dark, at: Coordinate(x: .c, y: .one)),
                            unsafeMiddleEntries: NonEmptyArray([
                                FlippableLine.Entry(unsafeDisk: .light, at: Coordinate(x: .b, y: .one)),
                            ])!,
                            unsafeLastEntry: FlippableLine.Entry(unsafeDisk: .none, at: Coordinate(x: .a, y: .one))
                        )
                    ])!
                ),
                expectedHistoryUntilNotAnimating: [
                    .flipping(at: Coordinate(x: .b, y: .one), with: .dark, restCoordinates: [], restLines: []),
                    .notAnimating,
                ]
            ),
            #line: TestCase(
                start: .placing(
                    at: Coordinate(x: .a, y: .one),
                    with: .dark,
                    restLines: NonEmptyArray([
                        FlippableLine(
                            line: Line(
                                start: Coordinate(x: .c, y: .one),
                                directedDistance: DirectedDistance(direction: .left, distance: .two)
                            )!,
                            unsafeFirstEntry: FlippableLine.Entry(unsafeDisk: .dark, at: Coordinate(x: .c, y: .one)),
                            unsafeMiddleEntries: NonEmptyArray([
                                FlippableLine.Entry(unsafeDisk: .light, at: Coordinate(x: .b, y: .one)),
                            ])!,
                            unsafeLastEntry: FlippableLine.Entry(unsafeDisk: .none, at: Coordinate(x: .a, y: .one))
                        ),
                        FlippableLine(
                            line: Line(
                                start: Coordinate(x: .a, y: .three),
                                directedDistance: DirectedDistance(direction: .top, distance: .two)
                            )!,
                            unsafeFirstEntry: FlippableLine.Entry(unsafeDisk: .dark, at: Coordinate(x: .a, y: .three)),
                            unsafeMiddleEntries: NonEmptyArray([
                                FlippableLine.Entry(unsafeDisk: .light, at: Coordinate(x: .a, y: .two)),
                            ])!,
                            unsafeLastEntry: FlippableLine.Entry(unsafeDisk: .none, at: Coordinate(x: .a, y: .one))
                        ),
                    ])!
                ),
                expectedHistoryUntilNotAnimating: [
                    .flipping(at: Coordinate(x: .b, y: .one), with: .dark, restCoordinates: [], restLines: [
                        FlippableLine(
                            line: Line(
                                start: Coordinate(x: .a, y: .three),
                                directedDistance: DirectedDistance(direction: .top, distance: .two)
                            )!,
                            unsafeFirstEntry: FlippableLine.Entry(unsafeDisk: .dark, at: Coordinate(x: .a, y: .three)),
                            unsafeMiddleEntries: NonEmptyArray([
                                FlippableLine.Entry(unsafeDisk: .light, at: Coordinate(x: .a, y: .two)),
                            ])!,
                            unsafeLastEntry: FlippableLine.Entry(unsafeDisk: .none, at: Coordinate(x: .a, y: .one))
                        ),
                    ]),
                    .flipping(at: Coordinate(x: .a, y: .two), with: .dark, restCoordinates: [], restLines: []),
                    .notAnimating,
                ]
            ),
        ]

        testCases.forEach {
            let (line, testCase) = $0

            var actualHistoryUntilNotAnimating = [BoardAnimationModelState]()
            var state = testCase.start
            while state != .notAnimating {
                state = state.nextForAnimationCompletion!
                actualHistoryUntilNotAnimating.append(state)
            }

            XCTAssertEqual(
                actualHistoryUntilNotAnimating, testCase.expectedHistoryUntilNotAnimating,
                diff(between: testCase.expectedHistoryUntilNotAnimating, and: actualHistoryUntilNotAnimating),
                line: line
            )
        }
    }
}
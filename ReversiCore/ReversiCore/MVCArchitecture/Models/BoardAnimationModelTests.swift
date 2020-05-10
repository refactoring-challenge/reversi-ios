import XCTest
import MirrorDiffKit
import ReversiCore



class BoardAnimationModelTests: XCTestCase {
    func testNext() {
        struct TestCase {
            let start: BoardAnimationModelState
            let expectedHistoryUntilNotAnimating: [Coordinate]
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
                    Coordinate(x: .b, y: .one),
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
                    Coordinate(x: .b, y: .one),
                    Coordinate(x: .a, y: .two),
                ]
            ),
            #line: TestCase(
                start: .placing(
                    at: Coordinate(x: .a, y: .one),
                    with: .dark,
                    restLines: NonEmptyArray([
                        FlippableLine(
                            line: Line(
                                start: Coordinate(x: .e, y: .one),
                                directedDistance: DirectedDistance(direction: .left, distance: .four)
                            )!,
                            unsafeFirstEntry: FlippableLine.Entry(unsafeDisk: .dark, at: Coordinate(x: .e, y: .one)),
                            unsafeMiddleEntries: NonEmptyArray([
                                FlippableLine.Entry(unsafeDisk: .light, at: Coordinate(x: .d, y: .one)),
                                FlippableLine.Entry(unsafeDisk: .light, at: Coordinate(x: .c, y: .one)),
                                FlippableLine.Entry(unsafeDisk: .light, at: Coordinate(x: .b, y: .one)),
                            ])!,
                            unsafeLastEntry: FlippableLine.Entry(unsafeDisk: .none, at: Coordinate(x: .a, y: .one))
                        )
                    ])!
                ),
                expectedHistoryUntilNotAnimating: [
                    Coordinate(x: .b, y: .one),
                    Coordinate(x: .c, y: .one),
                    Coordinate(x: .d, y: .one),
                ]
            ),
        ]

        testCases.forEach {
            let (line, testCase) = $0

            var actualHistoryUntilNotAnimating = [Coordinate]()
            var prevState = testCase.start
            while let state = prevState.nextForAnimationCompletion {
                if state == .notAnimating { break }
                actualHistoryUntilNotAnimating.append(state.animatingCoordinate!)
                prevState = state
            }

            XCTAssertEqual(
                actualHistoryUntilNotAnimating, testCase.expectedHistoryUntilNotAnimating,
                diff(between: testCase.expectedHistoryUntilNotAnimating, and: actualHistoryUntilNotAnimating),
                line: line
            )
        }
    }
}
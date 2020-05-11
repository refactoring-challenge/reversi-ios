import XCTest
import MirrorDiffKit
import ReversiCore



class BoardAnimationModelTests: XCTestCase {
    func testNext() {
        struct TestCase {
            let start: BoardAnimationModelState
            let expectedHistoryUntilNotAnimating: [Coordinate]
        }



        // NOTE: Target location that will be placed a disk.
        let target: Disk? = nil

        let testCases: [UInt: TestCase] = [
            #line: TestCase(
                start: .placing(
                    at: Coordinate(x: .a, y: .one),
                    with: .dark,
                    restLines: NonEmptyArray([
                        FlippableLine(
                            board: Board(unsafeArray: [
                                [target, .light, .dark, nil, nil, nil, nil, nil],
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
                            )!,
                            turn: .first
                        )!,
                    ])!
                ),
                expectedHistoryUntilNotAnimating: [
                    Coordinate(x: .a, y: .one),
                    Coordinate(x: .b, y: .one),
                ]
            ),
            #line: TestCase(
                start: .placing(
                    at: Coordinate(x: .a, y: .one),
                    with: .dark,
                    restLines: NonEmptyArray([
                        FlippableLine(
                            board: Board(unsafeArray: [
                                [target, .light, .dark, nil, nil, nil, nil, nil],
                                [.light, nil, nil, nil, nil, nil, nil, nil],
                                [.dark, nil, nil, nil, nil, nil, nil, nil],
                                [nil, nil, nil, nil, nil, nil, nil, nil],
                                [nil, nil, nil, nil, nil, nil, nil, nil],
                                [nil, nil, nil, nil, nil, nil, nil, nil],
                                [nil, nil, nil, nil, nil, nil, nil, nil],
                                [nil, nil, nil, nil, nil, nil, nil, nil],
                            ]),
                            line: Line(
                                start: Coordinate(x: .c, y: .one),
                                directedDistance: DirectedDistance(direction: .left, distance: .two)
                            )!,
                            turn: .first
                        )!,
                        FlippableLine(
                            board: Board(unsafeArray: [
                                [target, .light, .dark, nil, nil, nil, nil, nil],
                                [.light, nil, nil, nil, nil, nil, nil, nil],
                                [.dark, nil, nil, nil, nil, nil, nil, nil],
                                [nil, nil, nil, nil, nil, nil, nil, nil],
                                [nil, nil, nil, nil, nil, nil, nil, nil],
                                [nil, nil, nil, nil, nil, nil, nil, nil],
                                [nil, nil, nil, nil, nil, nil, nil, nil],
                                [nil, nil, nil, nil, nil, nil, nil, nil],
                            ]),
                            line: Line(
                                start: Coordinate(x: .a, y: .three),
                                directedDistance: DirectedDistance(direction: .top, distance: .two)
                            )!,
                            turn: .first
                        )!,
                    ])!
                ),
                expectedHistoryUntilNotAnimating: [
                    Coordinate(x: .a, y: .one),
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
                            board: Board(unsafeArray: [
                                [target, .light, .light, .light, .dark, nil, nil, nil],
                                [nil, nil, nil, nil, nil, nil, nil, nil],
                                [nil, nil, nil, nil, nil, nil, nil, nil],
                                [nil, nil, nil, nil, nil, nil, nil, nil],
                                [nil, nil, nil, nil, nil, nil, nil, nil],
                                [nil, nil, nil, nil, nil, nil, nil, nil],
                                [nil, nil, nil, nil, nil, nil, nil, nil],
                                [nil, nil, nil, nil, nil, nil, nil, nil],
                            ]),
                            line: Line(
                                start: Coordinate(x: .e, y: .one),
                                directedDistance: DirectedDistance(direction: .left, distance: .four)
                            )!,
                            turn: .first
                        )!,
                    ])!
                ),
                expectedHistoryUntilNotAnimating: [
                    Coordinate(x: .a, y: .one),
                    Coordinate(x: .b, y: .one),
                    Coordinate(x: .c, y: .one),
                    Coordinate(x: .d, y: .one),
                ]
            ),
        ]

        testCases.forEach {
            let (line, testCase) = $0

            var actualHistoryUntilNotAnimating = [Coordinate]()
            var prevState: BoardAnimationModelState? = testCase.start
            while let state = prevState {
                if state == .notAnimating {
                    break
                }
                actualHistoryUntilNotAnimating.append(state.animatingCoordinate!)
                prevState = state.nextForAnimationCompletion
            }

            XCTAssertEqual(
                actualHistoryUntilNotAnimating, testCase.expectedHistoryUntilNotAnimating,
                diff(between: testCase.expectedHistoryUntilNotAnimating, and: actualHistoryUntilNotAnimating),
                line: line
            )
        }
    }
}
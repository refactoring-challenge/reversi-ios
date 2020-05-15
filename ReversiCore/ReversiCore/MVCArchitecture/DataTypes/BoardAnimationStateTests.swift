import XCTest
import MirrorDiffKit
import ReversiCore



class BoardAnimationStateTests: XCTestCase {
    func testNext() {
        struct TestCase {
            let start: BoardAnimationState
            let expectedHistoryUntilNotAnimating: [Coordinate]
        }



        // NOTE: Target location that will be placed a disk.
        let target: Disk? = nil

        let testCases: [UInt: TestCase] = [
            #line: TestCase(
                start: .placing(
                    with: AvailableCandidate(
                        whose: .first,
                        unsafeCoordinateToPlace: Coordinate(x: .a, y: .one),
                        willFlipLines: NonEmptyArray([
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
                    in: BoardAnimationTransaction(
                        begin: Board(unsafeArray: [
                            [target, .light, .dark, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                        ]),
                        end: Board(unsafeArray: [
                            [.dark, .dark, .dark, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                        ])
                    )
                ),
                expectedHistoryUntilNotAnimating: [
                    Coordinate(x: .a, y: .one),
                    Coordinate(x: .b, y: .one),
                ]
            ),
            #line: TestCase(
                start: .placing(
                    with: AvailableCandidate(
                        whose: .first,
                        unsafeCoordinateToPlace: Coordinate(x: .a, y: .one),
                        willFlipLines: NonEmptyArray([
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
                    in: BoardAnimationTransaction(
                        begin: Board(unsafeArray: [
                            [target, .light, .dark, nil, nil, nil, nil, nil],
                            [.light, nil, nil, nil, nil, nil, nil, nil],
                            [.dark, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                        ]),
                        end: Board(unsafeArray: [
                            [.dark, .dark, .dark, nil, nil, nil, nil, nil],
                            [.dark, nil, nil, nil, nil, nil, nil, nil],
                            [.dark, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                        ])
                    )
                ),
                expectedHistoryUntilNotAnimating: [
                    Coordinate(x: .a, y: .one),
                    Coordinate(x: .b, y: .one),
                    Coordinate(x: .a, y: .two),
                ]
            ),
            #line: TestCase(
                start: .placing(
                    with: AvailableCandidate(
                        whose: .first,
                        unsafeCoordinateToPlace: Coordinate(x: .a, y: .one),
                        willFlipLines: NonEmptyArray([
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
                    in: BoardAnimationTransaction(
                        begin: Board(unsafeArray: [
                            [target, .light, .light, .light, .dark, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                        ]),
                        end: Board(unsafeArray: [
                            [.dark, .dark, .dark, .dark, .dark, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                            [nil, nil, nil, nil, nil, nil, nil, nil],
                        ])
                    )
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

            var actualHistoryWhileAnimating = [Coordinate]()
            var prevState: BoardAnimationState? = testCase.start
            while let state = prevState {
                guard state.isAnimating else { break }
                actualHistoryWhileAnimating.append(state.animatingCoordinate!)
                prevState = state.nextInTransaction
            }

            XCTAssertEqual(
                actualHistoryWhileAnimating, testCase.expectedHistoryUntilNotAnimating,
                diff(between: testCase.expectedHistoryUntilNotAnimating, and: actualHistoryWhileAnimating),
                line: line
            )
        }
    }
}
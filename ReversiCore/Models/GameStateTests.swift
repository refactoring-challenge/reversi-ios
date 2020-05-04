import XCTest
import MirrorDiffKit
@testable import ReversiCore



class GameStateTests: XCTestCase {
    func testPlay() {
        struct TestCase {
            let gameState: GameState
            let command: GameCommand
            let expected: GameState
        }



        let testCases: [UInt: TestCase] = [
            #line: TestCase(
                gameState: GameState(
                    board: Board<Disk?>(unsafeArray: [
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, .dark, .dark, .dark, nil, nil, .light],
                        [nil, nil, nil, .dark, .dark, .dark, .light, .light],
                        [nil, nil, nil, nil, nil, .dark, nil, .light],
                        [nil, nil, nil, nil, nil, .dark, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                    ]),
                    turn: .first
                ),
                command: .pass,
                expected: GameState(
                    board: Board<Disk?>(unsafeArray: [
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, .dark, .dark, .dark, nil, nil, .light],
                        [nil, nil, nil, .dark, .dark, .dark, .light, .light],
                        [nil, nil, nil, nil, nil, .dark, nil, .light],
                        [nil, nil, nil, nil, nil, .dark, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                    ]),
                    turn: .second
                )
            ),
            #line: TestCase(
                gameState: GameState(
                    board: Board<Disk?>(unsafeArray: [
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, .dark, .dark, .dark, nil, nil, .light],
                        [nil, nil, nil, .dark, .dark, .dark, .light, .light],
                        [nil, nil, nil, nil, nil, .dark, nil, .light],
                        [nil, nil, nil, nil, nil, .dark, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                    ]),
                    turn: .second
                ),
                command: .place(at: Coordinate(x: .e, y: .seven)),
                expected: GameState(
                    board: Board<Disk?>(unsafeArray: [
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                        [nil, nil, .dark, .dark, .dark, nil, nil, .light],
                        [nil, nil, nil, .dark, .dark, .dark, .light, .light],
                        [nil, nil, nil, nil, nil, .light, nil, .light],
                        [nil, nil, nil, nil, .light, .dark, nil, nil],
                        [nil, nil, nil, nil, nil, nil, nil, nil],
                    ]),
                    turn: .first
                )
            ),
        ]

        testCases.forEach {
            let (line, testCase) = $0

            let actual = testCase.command.unsafeExecute(on: testCase.gameState)
            XCTAssertEqual(actual, testCase.expected, diff(between: testCase.expected, and: actual))
        }
    }
}
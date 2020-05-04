import XCTest
import MirrorDiffKit
@testable import ReversiCore



class GameStateTests: XCTestCase {
    func testPlay() throws {
        struct TestCase {
            let gameState: GameState
            let command: GameCommand
            let expected: GameState
        }



        let testCases: [UInt: TestCase] = [
            #line: TestCase(
                gameState: GameState(
                    // SEE: Fig.6 of https://ja.wikipedia.org/wiki/%E3%82%AA%E3%82%BB%E3%83%AD_(%E3%83%9C%E3%83%BC%E3%83%89%E3%82%B2%E3%83%BC%E3%83%A0)#%E5%9F%BA%E6%9C%AC%E3%83%AB%E3%83%BC%E3%83%AB
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
                    turn: .first
                ),
                command: .pass,
                expected: GameState(
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
                    turn: .second
                )
            ),
            #line: TestCase(
                gameState: GameState(
                    board: Board(unsafeArray: [
                        // SEE: Fig.6 of https://ja.wikipedia.org/wiki/%E3%82%AA%E3%82%BB%E3%83%AD_(%E3%83%9C%E3%83%BC%E3%83%89%E3%82%B2%E3%83%BC%E3%83%A0)#%E5%9F%BA%E6%9C%AC%E3%83%AB%E3%83%BC%E3%83%AB
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
                    board: Board(unsafeArray: [
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

        try testCases.forEach {
            let (line, testCase) = $0

            let actual = try testCase.command.unsafeExecute(on: testCase.gameState)
            XCTAssertEqual(actual, testCase.expected, diff(between: testCase.expected, and: actual), line: line)
        }
    }
}
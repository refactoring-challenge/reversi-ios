import XCTest
import MirrorDiffKit
import ReversiCore



class GameStateTests: XCTestCase {
    func testPlay() throws {
        struct TestCase {
            let gameState: GameState
            let commands: [GameCommand]
            let expected: GameState
        }



        let testCases: [UInt: TestCase] = [
            #line: TestCase(
                gameState: .initial,
                commands: [
                    .place(at: Coordinate(x: .f, y: .five)),
                    .place(at: Coordinate(x: .f, y: .six)),
                    .place(at: Coordinate(x: .c, y: .four)),
                    .place(at: Coordinate(x: .g, y: .five)),
                    .place(at: Coordinate(x: .h, y: .five)),
                    .place(at: Coordinate(x: .h, y: .four)),
                    .place(at: Coordinate(x: .f, y: .seven)),
                    .place(at: Coordinate(x: .h, y: .six)),
                ],
                expected: GameState(
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
                )
            ),
            #line: TestCase(
                gameState: GameState(
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
                commands: [.pass],
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
                commands: [.place(at: Coordinate(x: .e, y: .seven))],
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

            let actual = try testCase.commands.reduce(testCase.gameState) { gameState, command in
                do {
                    let nextGameState = try command.unsafeExecute(on: gameState)
                    return nextGameState
                }
                catch {
                    XCTFail("\(error)")
                    throw error
                }
            }
            XCTAssertEqual(actual, testCase.expected, diff(between: testCase.expected, and: actual), line: line)
        }
    }
}
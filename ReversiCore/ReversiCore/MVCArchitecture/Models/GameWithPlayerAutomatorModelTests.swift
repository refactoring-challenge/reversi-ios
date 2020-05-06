import XCTest
import Hydra
import ReactiveSwift
import MirrorDiffKit
import ReversiCore



class GameWithPlayerAutomatorModelTests: XCTestCase {
    private let (lifetime, token) = ReactiveSwift.Lifetime.make()


    func testPvP() throws {
        let model = GameWithPlayerAutomatorModel(
            strategy: PlayerAutomator.pendingSelector,
            gameModel: GameModel(startsWith: .initial),
            playersAutomationAvailabilityModel: PlayersAutomationAvailabilityModel(
                startsWith: PlayersAutomationAvailability(
                    first: .disabled,
                    second: .disabled
                )
            )
        )

        XCTAssertEqual(model.gameModel.place(at: Coordinate(x: .f, y: .five)), .accepted)

        try self.waitUntilTurnReady(gameModel: model.gameModel, turn: .second)
        XCTAssertEqual(model.gameModel.place(at: Coordinate(x: .f, y: .six)), .accepted)

        try self.waitUntilTurnReady(gameModel: model.gameModel, turn: .first)
        XCTAssertEqual(model.gameModel.place(at: Coordinate(x: .c, y: .four)), .accepted)

        try self.waitUntilTurnReady(gameModel: model.gameModel, turn: .second)

        let actual = model.gameModel.stateDidChange.value.gameState
        let expected = GameState(
            board: Board(unsafeArray: [
                [nil, nil, nil, nil, nil, nil, nil, nil],
                [nil, nil, nil, nil, nil, nil, nil, nil],
                [nil, nil, nil, nil, nil, nil, nil, nil],
                [nil, nil, .dark, .dark, .dark, nil, nil, nil],
                [nil, nil, nil, .dark, .light, .dark, nil, nil],
                [nil, nil, nil, nil, nil, .light, nil, nil],
                [nil, nil, nil, nil, nil, nil, nil, nil],
                [nil, nil, nil, nil, nil, nil, nil, nil],
            ]),
            turn: .second
        )
        XCTAssertEqual(actual, expected, diff(between: expected, and: actual))
    }


    func testPvC() throws {
        let model = GameWithPlayerAutomatorModel(
            // NOTE: Use topLeftSelector to make the last board consistent.
            strategy: PlayerAutomator.topLeftSelector,
            gameModel: GameModel(startsWith: .initial),
            playersAutomationAvailabilityModel: PlayersAutomationAvailabilityModel(
                startsWith: PlayersAutomationAvailability(
                    first: .disabled,
                    second: .enabled
                )
            )
        )

        XCTAssertEqual(model.gameModel.place(at: Coordinate(x: .f, y: .five)), .accepted)

        // NOTE: topLeftSelector will place at f4.

        try self.waitUntilTurnReady(gameModel: model.gameModel, turn: .first)
        XCTAssertEqual(model.gameModel.place(at: Coordinate(x: .e, y: .three)), .accepted)

        // NOTE: topLeftSelector will place at d2.

        try self.waitUntilTurnReady(gameModel: model.gameModel, turn: .first)

        let actual = model.gameModel.stateDidChange.value.gameState
        let expected = GameState(
            board: Board(unsafeArray: [
                [nil, nil, nil, nil, nil, nil, nil, nil],
                [nil, nil, nil, .light, nil, nil, nil, nil],
                [nil, nil, nil, nil, .light, nil, nil, nil],
                [nil, nil, nil, .light, .dark, .light, nil, nil],
                [nil, nil, nil, .dark, .dark, .dark, nil, nil],
                [nil, nil, nil, nil, nil, nil, nil, nil],
                [nil, nil, nil, nil, nil, nil, nil, nil],
                [nil, nil, nil, nil, nil, nil, nil, nil],
            ]),
            turn: .first
        )
        XCTAssertEqual(actual, expected, diff(between: expected, and: actual))
    }


    func testCvC() throws {
        let model = GameWithPlayerAutomatorModel(
            // NOTE: Use topLeftSelector to make the last board consistent.
            strategy: PlayerAutomator.topLeftSelector,
            gameModel: GameModel(startsWith: .initial),
            playersAutomationAvailabilityModel: PlayersAutomationAvailabilityModel(
                startsWith: PlayersAutomationAvailability(
                    first: .enabled,
                    second: .enabled
                )
            )
        )

        try self.waitUntilGameSet(gameModel: model.gameModel)

        let actual = model.gameModel.stateDidChange.value.gameState
        let expected = GameState(
            board: Board(unsafeArray: [
                [.light, .light, .light, .light, .light, .light, .light, .dark ],
                [.light, .light, .light, .light, .light, .light, .dark, .dark ],
                [.light, .light, .light, .light, .light, .dark, .light, .dark ],
                [.light, .light, .light, .light, .dark, .light, .light, .dark ],
                [.light, .light, .light, .light, .light, .light, .light, .dark ],
                [.light, .light, .light, .dark, .light, .light, .light, .dark ],
                [.light, .light, .light, .light, .dark, .dark, .light, .dark ],
                [.dark, .dark, .dark, .dark, .dark, .dark, .light, .light ],
            ]),
            turn: .first
        )
        XCTAssertEqual(actual, expected, diff(between: expected, and: actual))
    }


    private func waitUntilTurnReady(gameModel: GameModelProtocol, turn: Turn, line: UInt = #line) throws {
        try self.waitUntilGameState(gameModel: gameModel, line: line) { gameModelState -> Bool in
            switch gameModelState {
            case .completed, .processing:
                return false
            case .ready(let gameState, _):
                return gameState.turn == turn
            }
        }
    }


    private func waitUntilGameSet(gameModel: GameModelProtocol, line: UInt = #line) throws {
        try self.waitUntilGameState(gameModel: gameModel, line: line) { gameModelState -> Bool in
            switch gameModelState {
            case .processing, .ready:
                return false
            case .completed:
                return true
            }
        }
    }


    private func waitUntilGameState(gameModel: GameModelProtocol, line: UInt = #line, _ condition: @escaping (GameModelState) -> Bool) throws {
        let result = gameModel.stateDidChange
            .producer
            .take(during: self.lifetime)
            .filter(condition)
            .take(first: 1)
            .timeout(after: 10, raising: TimeoutExceeded(), on: ReactiveSwift.QueueScheduler())
            .single()!

        switch result {
        case .success:
            return

        case .failure(let error):
            XCTFail("\(error)", line: line)
            throw error
        }
    }


    struct TimeoutExceeded: Error {}
}
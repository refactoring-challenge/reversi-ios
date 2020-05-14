import XCTest
import Hydra
import ReactiveSwift
import MirrorDiffKit
import ReversiCore



class GameWithAutomatorsModelTests: XCTestCase {
    private let (lifetime, token) = ReactiveSwift.Lifetime.make()


    func testPvP() throws {
        self.continueAfterFailure = false

        let model = GameWithAutomatorsModel(
            automatableGameModel: GameModel(initialState: .initial),
            // NOTE: Use topLeftSelector to make deterministic.
            automatorModel: GameAutomatorModel(
                strategy: GameAutomator.topLeftSelector
            ),
            automationAvailabilityModel: GameAutomatorAvailabilitiesModel(
                startsWith: GameAutomatorAvailabilities(
                    first: .disabled,
                    second: .disabled
                )
            )
        )

        XCTAssertEqual(model.place(at: Coordinate(x: .f, y: .five)), .accepted)

        try self.waitUntilTurnReady(model, turn: .second)
        XCTAssertEqual(model.place(at: Coordinate(x: .f, y: .six)), .accepted)

        try self.waitUntilTurnReady(model, turn: .first)
        XCTAssertEqual(model.place(at: Coordinate(x: .c, y: .four)), .accepted)

        try self.waitUntilTurnReady(model, turn: .second)

        let actual = model.gameWithAutomatorsModelStateDidChange.value.gameState
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
        self.continueAfterFailure = false

        let model = GameWithAutomatorsModel(
            automatableGameModel: GameModel(initialState: .initial),
            automatorModel: GameAutomatorModel(
                // NOTE: Use topLeftSelector to make deterministic.
                strategy: GameAutomator.topLeftSelector
            ),
            automationAvailabilityModel: GameAutomatorAvailabilitiesModel(
                startsWith: GameAutomatorAvailabilities(
                    first: .disabled,
                    second: .enabled
                )
            )
        )

        XCTAssertEqual(model.place(at: Coordinate(x: .f, y: .five)), .accepted)

        // NOTE: topLeftSelector will place at f4.

        try self.waitUntilTurnReady(model, turn: .first)
        XCTAssertEqual(model.place(at: Coordinate(x: .e, y: .three)), .accepted)

        // NOTE: topLeftSelector will place at d2.

        try self.waitUntilTurnReady(model, turn: .first)

        let actual = model.gameWithAutomatorsModelStateDidChange.value.gameState
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
        self.continueAfterFailure = false

        let model = GameWithAutomatorsModel(
            automatableGameModel: GameModel(initialState: .initial),
            automatorModel: GameAutomatorModel(
                // NOTE: Use topLeftSelector to make deterministic.
                strategy: GameAutomator.topLeftSelector
            ),
            automationAvailabilityModel: GameAutomatorAvailabilitiesModel(
                startsWith: GameAutomatorAvailabilities(
                    first: .enabled,
                    second: .enabled
                )
            )
        )
        let passAutomator = PassAutomator(gameWithAutomatorsModel: model)

        try self.waitUntilGameSet(model)
        _ = passAutomator

        let actual = model.gameWithAutomatorsModelStateDidChange.value.gameState
        let expected = GameState(
            board: Board(unsafeArray: [
                [.light, .light, .light, .light, .light, .light, .light, .dark],
                [.light, .light, .light, .light, .light, .light, .dark, .dark],
                [.light, .light, .light, .light, .light, .dark, .light, .dark],
                [.light, .light, .light, .light, .dark, .light, .light, .dark],
                [.light, .light, .light, .light, .light, .light, .light, .dark],
                [.light, .light, .light, .dark, .light, .light, .light, .dark],
                [.light, .light, .light, .light, .dark, .dark, .light, .dark],
                [.dark, .dark, .dark, .dark, .dark, .dark, .light, .light],
            ]),
            turn: .first
        )
        XCTAssertEqual(actual, expected, diff(between: expected, and: actual))
    }


    private func waitUntilTurnReady(
        _ gameWithAutomatorsModel: GameWithAutomatorsModelProtocol,
        turn: Turn,
        line: UInt = #line
    ) throws {
        try self.waitUntilGameState(gameWithAutomatorsModel, line: line) { gameModelState -> Bool in
            switch gameModelState {
            case .completed, .automatorThinking, .awaitingReadyOrCompleted, .failed:
                return false
            case .mustPass(on: let gameState), .mustPlace(at: _, on: let gameState):
                return gameState.turn == turn
            }
        }
    }


    private func waitUntilGameSet(
        _ gameWithAutomatorsModel: GameWithAutomatorsModelProtocol,
        line: UInt = #line
    ) throws {
        try self.waitUntilGameState(gameWithAutomatorsModel, line: line) { gameModelState -> Bool in
            switch gameModelState {
            case .mustPlace, .mustPass, .automatorThinking, .awaitingReadyOrCompleted, .failed:
                return false
            case .completed:
                return true
            }
        }
    }


    private func waitUntilGameState(
        _ gameWithAutomatorsModel: GameWithAutomatorsModelProtocol,
        line: UInt = #line,
        _ condition: @escaping (GameWithAutomatorsModelState) -> Bool
    ) throws {
        let result = gameWithAutomatorsModel.gameWithAutomatorsModelStateDidChange
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



    private class PassAutomator {
        private let gameWithAutomatorsModel: GameWithAutomatorsModelProtocol
        private let (lifetime, token) = ReactiveSwift.Lifetime.make()


        public init(gameWithAutomatorsModel: GameWithAutomatorsModelProtocol) {
            self.gameWithAutomatorsModel = gameWithAutomatorsModel

            gameWithAutomatorsModel.gameWithAutomatorsModelStateDidChange
                .producer
                .take(during: self.lifetime)
                .observe(on: QueueScheduler(qos: .userInteractive))
                .on(value: { [weak self] state in
                    switch state {
                    case .mustPass:
                        self?.gameWithAutomatorsModel.pass()
                    case .mustPlace, .automatorThinking, .awaitingReadyOrCompleted, .failed, .completed:
                        return
                    }
                })
                .start()
        }
    }
}
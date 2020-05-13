import Dispatch
import ReactiveSwift



public protocol GameWithAutomatorsModelProtocol: GameCommandReceivable, GameAutomatorAvailabilitiesModelProtocol, GameAutomatorProgressModelProtocol {
    var gameWithAutomatorsModelStateDidChange: ReactiveSwift.Property<GameWithAutomatorsModelState> { get }
    @discardableResult func cancel() -> GameCommandResult
}



public extension GameWithAutomatorsModelProtocol {
    var gameWithAutomatorsModelState: GameWithAutomatorsModelState { self.gameWithAutomatorsModelStateDidChange.value }
}



public class GameWithAutomatorsModel: GameWithAutomatorsModelProtocol {
    public let gameWithAutomatorsModelStateDidChange: ReactiveSwift.Property<GameWithAutomatorsModelState>
    public var gameWithAutomatorsModelState: GameWithAutomatorsModelState {
        self.gameWithAutomatorsModelStateDidChange.value
    }
    public var automatorDidProgress: ReactiveSwift.Property<GameAutomatorProgress> {
        self.automatorModel.automatorDidProgress
    }

    private let automatableGameModel: AutomatableGameModelProtocol
    private let automationAvailabilityModel: GameAutomatorAvailabilitiesModelProtocol
    private let automatorModel: GameAutomatorModelProtocol
    private let automatorDidFail: ReactiveSwift.MutableProperty<GameWithAutomatorsModelState.FailureReason?>

    private let (lifetime, token) = ReactiveSwift.Lifetime.make()


    public init(
        automatableGameModel: AutomatableGameModelProtocol,
        automatorModel: GameAutomatorModelProtocol,
        automationAvailabilityModel: GameAutomatorAvailabilitiesModelProtocol
    ) {
        self.automatableGameModel = automatableGameModel
        self.automationAvailabilityModel = automationAvailabilityModel
        self.automatorModel = automatorModel

        let automatorDidFail = ReactiveSwift.MutableProperty<GameWithAutomatorsModelState.FailureReason?>(nil)
        self.automatorDidFail = automatorDidFail

        self.gameWithAutomatorsModelStateDidChange = ReactiveSwift.Property
            .combineLatest(
                automatableGameModel.automatableGameStateDidChange,
                automationAvailabilityModel.availabilitiesDidChange,
                automatorModel.automatorDidProgress,
                automatorDidFail
            )
            .map {
                let (boardAvailability, automationAvailabilities, automatorProgress, lastFailureReason) = $0
                return GameWithAutomatorsModelState.from(
                    automatableGameState: boardAvailability,
                    automatorAvailabilities: automationAvailabilities,
                    automatorProgress: automatorProgress,
                    lastFailureReason: lastFailureReason
                )
            }

        self.start()
    }


    private func start() {
        // BUG8: Signal from Property does not receive the current value at first.
        ReactiveSwift.Property
            .combineLatest(
                self.automatableGameModel.automatableGameStateDidChange,
                self.automationAvailabilityModel.availabilitiesDidChange
            )
            .producer
            .take(during: self.lifetime)
            .observe(on: QueueScheduler(qos: .userInitiated))
            .on(value: { [weak self] (pair: (AutomatableGameModelState, GameAutomatorAvailabilities)) in
                guard let self = self else { return }
                let (boardAvailability, automationAvailabilities) = pair
                switch boardAvailability {
                case .notReady, .completed:
                    return

                case .ready(let gameState, availableCandidates: let availableCandidates):
                    switch automationAvailabilities.availability(on: gameState) {
                    case .disabled:
                        return

                    case .enabled:
                        guard let nonEmptyAvailableCandidates = NonEmptyArray(availableCandidates) else {
                            // NOTE: User must confirm if the automator do pass.
                            return
                        }

                        self.automatorModel.runAutomator(inThisTurn: gameState.turn, for: nonEmptyAvailableCandidates)
                    }
                }
            })
            .start()

        automatorModel.automatorDidChoice
            .producer
            .take(during: self.lifetime)
            .observe(on: QueueScheduler(qos: .userInitiated))
            .on(value: { [weak self] selected in
                guard let self = self else { return }
                switch self.automatableGameModel.place(at: selected.coordinate) {
                case .ignored:
                    self.automatorDidFail.value = .placeNotAccepted
                    return
                case .accepted:
                    return
                }
            })
            .start()
    }


    @discardableResult
    public func cancel() -> GameCommandResult {
        switch self.automatorModel.cancel() {
        case .ignored:
            return .ignored
        case .accepted:
            return .accepted
        }
    }
}



extension GameWithAutomatorsModel: GameCommandReceivable {
    @discardableResult
    public func pass() -> GameCommandResult {
        switch self.gameWithAutomatorsModelState {
        case .failed:
            return .ignored

        case .ready, .completed, .awaitingReadyOrCompleted, .automatorThinking:
            return self.automatableGameModel.pass()
        }
    }


    @discardableResult
    public func place(at coordinate: Coordinate) -> GameCommandResult {
        switch self.gameWithAutomatorsModelState {
        case .automatorThinking, .failed:
            return .ignored

        case .ready, .completed, .awaitingReadyOrCompleted:
            return self.automatableGameModel.place(at: coordinate)
        }
    }


    @discardableResult
    public func reset() -> GameCommandResult {
        self.cancel()
        return self.automatableGameModel.reset()
    }
}



extension GameWithAutomatorsModel: GameAutomatorAvailabilitiesModelProtocol {
    public var availabilitiesDidChange: Property<GameAutomatorAvailabilities> {
        self.automationAvailabilityModel.availabilitiesDidChange
    }


    public func update(availabilities: GameAutomatorAvailabilities) {
        switch self.gameWithAutomatorsModelState {
        case .failed:
            return

        case .ready, .completed, .awaitingReadyOrCompleted:
            break

        case .automatorThinking(previousGameState: let prevGameState, previousAvailableCandidates: _):
            // NOTE: Should cancel if the availability to update is processing.
            let shouldCancelCurrentAutomatorTask = availabilities.availability(on: prevGameState) == .disabled
            if shouldCancelCurrentAutomatorTask {
                self.automatorModel.cancel()
            }
        }

        self.automationAvailabilityModel.update(availabilities: availabilities)
    }
}



public enum GameWithAutomatorsModelState {
    case ready(GameState, availableCandidates: Set<AvailableCandidate>)
    case completed(GameState, result: GameResult)
    case awaitingReadyOrCompleted(previousGameState: GameState, previousAvailableCandidates: Set<AvailableCandidate>)
    case failed(GameState, because: FailureReason)
    case automatorThinking(previousGameState: GameState, previousAvailableCandidates: Set<AvailableCandidate>)


    public var gameState: GameState {
        switch self {
        case .ready(let gameState, availableCandidates: _), .completed(let gameState, result: _),
             .awaitingReadyOrCompleted(previousGameState: let gameState, previousAvailableCandidates: _),
             .automatorThinking(previousGameState: let gameState, previousAvailableCandidates: _),
             .failed(let gameState, because: _):
            return gameState
        }
    }

    public var turn: Turn { self.gameState.turn }
    public var board: Board { self.gameState.board }


    public var playerMustPass: Bool {
        switch self {
        case .completed, .awaitingReadyOrCompleted, .failed:
            return false
        case .ready(_, availableCandidates: let availableCandidates),
             .automatorThinking(previousGameState: _, previousAvailableCandidates: let availableCandidates):
            return availableCandidates.isEmpty
        }
    }


    public static func from(
        automatableGameState: AutomatableGameModelState,
        automatorAvailabilities: GameAutomatorAvailabilities,
        automatorProgress: GameAutomatorProgress,
        lastFailureReason: FailureReason?
    ) -> GameWithAutomatorsModelState {
        if let failureReason = lastFailureReason {
            return .failed(automatableGameState.gameState, because: failureReason)
        }

        switch automatorProgress {
        case .thinking(on: _, within: let availableCandidates, cancelToken: _):
            return .automatorThinking(
                previousGameState: automatableGameState.gameState,
                previousAvailableCandidates: Set(availableCandidates.toArray())
            )

        case .sleeping:
            switch automatableGameState {
            case .notReady:
                return .awaitingReadyOrCompleted(
                    previousGameState: automatableGameState.gameState,
                    previousAvailableCandidates: automatableGameState.availableCandidates
                )

            case .ready(let gameState, availableCandidates: let availableCandidates):
                switch automatorAvailabilities.availability(on: gameState) {
                case .enabled:
                    return .automatorThinking(
                        previousGameState: gameState,
                        previousAvailableCandidates: availableCandidates
                    )
                case .disabled:
                    return .ready(gameState, availableCandidates: availableCandidates)
                }

            case .completed(let gameState, result: let gameResult):
                return .completed(gameState, result: gameResult)
            }
        }
    }



    public enum FailureReason {
        case passNotAccepted
        case placeNotAccepted
    }
}

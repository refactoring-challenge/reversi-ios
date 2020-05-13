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

                case .mustPass:
                    // NOTE: User must confirm if the automator do pass.
                    return

                case .mustPlace(anywhereIn: let availableCandidates, on: let gameState):
                    switch automationAvailabilities.availability(on: gameState) {
                    case .disabled:
                        return

                    case .enabled:
                        self.automatorModel.runAutomator(inThisTurn: gameState.turn, for: availableCandidates)
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
                    self.automatorDidFail.value = .placeNotAccepted(at: selected)
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

        case .mustPass, .mustPlace, .completed, .awaitingReadyOrCompleted, .automatorThinking:
            return self.automatableGameModel.pass()
        }
    }


    @discardableResult
    public func place(at coordinate: Coordinate) -> GameCommandResult {
        switch self.gameWithAutomatorsModelState {
        case .automatorThinking, .failed:
            return .ignored

        case .mustPlace, .mustPass, .completed, .awaitingReadyOrCompleted:
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

        case .mustPass, .mustPlace, .completed, .awaitingReadyOrCompleted:
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
    case mustPlace(at: NonEmptyArray<AvailableCandidate>, on: GameState)
    case mustPass(on: GameState)
    case completed(with: GameResult, on: GameState)
    case awaitingReadyOrCompleted(previousGameState: GameState, previousAvailableCandidates: NonEmptyArray<AvailableCandidate>?)
    case failed(GameState, because: FailureReason)
    case automatorThinking(previousGameState: GameState, previousAvailableCandidates: NonEmptyArray<AvailableCandidate>?)


    public var gameState: GameState {
        switch self {
        case .mustPlace(at: _, on: let gameState), .mustPass(on: let gameState), .completed(with: _, let gameState),
             .awaitingReadyOrCompleted(previousGameState: let gameState, previousAvailableCandidates: _),
             .automatorThinking(previousGameState: let gameState, previousAvailableCandidates: _),
             .failed(let gameState, because: _):
            return gameState
        }
    }

    public var turn: Turn { self.gameState.turn }
    public var board: Board { self.gameState.board }


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
                previousAvailableCandidates: availableCandidates
            )

        case .sleeping:
            switch automatableGameState {
            case .notReady:
                return .awaitingReadyOrCompleted(
                    previousGameState: automatableGameState.gameState,
                    previousAvailableCandidates: automatableGameState.availableCandidates
                )

            case .mustPass(on: let gameState):
                return .mustPass(on: gameState)

            case .mustPlace(anywhereIn: let availableCandidates, on: let gameState):
                switch automatorAvailabilities.availability(on: gameState) {
                case .enabled:
                    return .automatorThinking(
                        previousGameState: gameState,
                        previousAvailableCandidates: availableCandidates
                    )
                case .disabled:
                    return .mustPlace(at: availableCandidates, on: gameState)
                }

            case .completed(with: let gameResult, on: let gameState):
                return .completed(with: gameResult, on: gameState)
            }
        }
    }



    public enum FailureReason {
        case placeNotAccepted(at: AvailableCandidate)
    }
}

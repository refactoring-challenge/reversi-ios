import ReactiveSwift



public protocol AutomatableGameModelProtocol: class {
    var automatableGameStateDidChange: ReactiveSwift.Property<AutomatableGameModelState> { get }
    func pass() -> AutomatableGameCommandResult
    func place(at: Coordinate) -> AutomatableGameCommandResult
    func reset() -> AutomatableGameCommandResult
}



public extension AutomatableGameModelProtocol {
    var automatableGameState: AutomatableGameModelState {
        self.automatableGameStateDidChange.value
    }
}



public enum AutomatableGameModelState {
    case ready(GameState, availableCandidates: Set<AvailableCandidate>)
    case completed(GameState, result: GameResult)
    case notReady(GameState, availableCandidates: Set<AvailableCandidate>)


    var gameState: GameState {
        switch self {
        case .ready(let gameState, availableCandidates: _), .completed(let gameState, result: _),
             .notReady(let gameState, availableCandidates: _):
            return gameState
        }
    }


    var availableCandidates: Set<AvailableCandidate> {
        switch self {
        case .ready(_, availableCandidates: let availableCandidates), .notReady(_, availableCandidates: let availableCandidates):
            return availableCandidates
        case .completed:
            return Set()
        }
    }


    var turn: Turn { self.gameState.turn }
}



public enum AutomatableGameCommandResult {
    case accepted
    case ignored
}



extension AutomatableGameCommandResult: Equatable {}

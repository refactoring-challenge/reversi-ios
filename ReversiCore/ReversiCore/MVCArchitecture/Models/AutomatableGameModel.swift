import ReactiveSwift



public protocol AutomatableGameModelProtocol: GameCommandReceivable {
    var automatableGameStateDidChange: ReactiveSwift.Property<AutomatableGameModelState> { get }
}



public extension AutomatableGameModelProtocol {
    var automatableGameState: AutomatableGameModelState {
        self.automatableGameStateDidChange.value
    }
}



public enum AutomatableGameModelState {
    case mustPlace(anywhereIn: NonEmptyArray<AvailableCandidate>, on: GameState)
    case mustPass(on: GameState)
    case completed(with: GameResult, on: GameState)
    case notReady(lastAvailableCandidates: NonEmptyArray<AvailableCandidate>?, lastGameState: GameState)


    var gameState: GameState {
        switch self {
        case .mustPlace(anywhereIn: _, let gameState), .mustPass(on: let gameState), .completed(with: _, let gameState),
             .notReady(lastAvailableCandidates: _, lastGameState: let gameState):
            return gameState
        }
    }


    var availableCandidates: NonEmptyArray<AvailableCandidate>? {
        switch self {
        case .mustPlace(anywhereIn: let availableCandidates, on: _):
            return availableCandidates
        case .notReady(lastAvailableCandidates: let availableCandidates, lastGameState: _):
            return availableCandidates
        case .completed, .mustPass:
            return nil
        }
    }


    var turn: Turn { self.gameState.turn }
}

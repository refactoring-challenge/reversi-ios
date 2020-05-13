import ReactiveSwift



extension GameModelState {
    public func toAutomatableGameState() -> AutomatableGameModelState {
        switch self {
        case .mustPlace(anywhereIn: let availableCandidates, on: let gameState):
            return .mustPlace(anywhereIn: availableCandidates, on: gameState)
        case .mustPass(on: let gameState):
            return .mustPass(on: gameState)
        case .completed(with: let gameResult, on: let gameState):
            return .completed(with: gameResult, on: gameState)
        }
    }
}



extension GameCommandResult {
    public func toAutomatableGameCommandResult() -> GameCommandResult {
        switch self {
        case .accepted:
            return .accepted
        case .ignored:
            return .ignored
        }
    }
}



extension GameModel: AutomatableGameModelProtocol {
    public var automatableGameStateDidChange: ReactiveSwift.Property<AutomatableGameModelState> {
        self.gameModelStateDidChange.map { $0.toAutomatableGameState() }
    }
}
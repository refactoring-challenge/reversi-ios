import ReactiveSwift



extension GameModelState {
    public func toAutomatableGameState() -> AutomatableGameModelState {
        switch self {
        case .ready(let gameState, let availableCandidates):
            return .ready(gameState, availableCandidates: availableCandidates)
        case .completed(let gameState, let gameResult):
            return .completed(gameState, result: gameResult)
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
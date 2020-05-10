import ReactiveSwift



extension AnimatedGameModelState {
    public func toAutomatableGameState() -> AutomatableGameModelState {
        switch self {
        case .ready(let gameState, let availableCandidates, let isAnimating):
            return isAnimating
                ? .notReady(gameState, availableCandidates: availableCandidates)
                : .ready(gameState, availableCandidates: availableCandidates)

        case .completed(let gameState, let gameResult, let isAnimating):
            return isAnimating
                ? .notReady(gameState, availableCandidates: availableCandidates)
                : .completed(gameState, result: gameResult)
        }
    }
}



extension AnimatedGameModel: AutomatableGameModelProtocol {
    public var automatableGameStateDidChange: ReactiveSwift.Property<AutomatableGameModelState> {
        self.animatedGameStateDidChange.map { $0.toAutomatableGameState() }
    }
}

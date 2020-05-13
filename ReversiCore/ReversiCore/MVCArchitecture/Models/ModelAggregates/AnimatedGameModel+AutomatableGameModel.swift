import ReactiveSwift



extension AnimatedGameModelState {
    public func toAutomatableGameState() -> AutomatableGameModelState {
        switch self {
        case .mustPass(on: let gameState, isAnimating: let isAnimating):
            return isAnimating
                ? .notReady(lastAvailableCandidates: nil, lastGameState: gameState)
                : .mustPass(on: gameState)

        case .mustPlace(anywhereIn: let availableCandidates, on: let gameState, isAnimating: let isAnimating):
            return isAnimating
                ? .notReady(lastAvailableCandidates: availableCandidates, lastGameState: gameState)
                : .mustPlace(anywhereIn: availableCandidates, on: gameState)

        case .completed(with: let gameResult, on: let gameState, isAnimating: let isAnimating):
            return isAnimating
                ? .notReady(lastAvailableCandidates: availableCandidates, lastGameState: gameState)
                : .completed(with: gameResult, on: gameState)
        }
    }
}



extension AnimatedGameModel: AutomatableGameModelProtocol {
    public var automatableGameStateDidChange: ReactiveSwift.Property<AutomatableGameModelState> {
        self.animatedGameStateDidChange.map { $0.toAutomatableGameState() }
    }
}

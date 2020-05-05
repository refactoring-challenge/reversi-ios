import ReactiveSwift



enum PlayerAutomationProgressModelState {
    case working(for: Turn)
    case sleeping
}



extension PlayerAutomationProgressModelState: Equatable {}



protocol PlayerAutomationProgressModelProtocol {
    var progressDidChange: ReactiveSwift.Property<PlayerAutomationProgressModelState> { get }
}



class PlayerAutomationProgressModel: PlayerAutomationProgressModelProtocol {
    let progressDidChange: ReactiveSwift.Property<PlayerAutomationProgressModelState>


    init(observing gameModel: GameModelProtocol) {
        self.progressDidChange = gameModel.stateDidChange
            .map { gameModelState in
                switch gameModelState {
                case .completed, .ready:
                    return .sleeping
                case .processing(previous: let gameState):
                    return .working(for: gameState.turn)
                }
            }
    }
}
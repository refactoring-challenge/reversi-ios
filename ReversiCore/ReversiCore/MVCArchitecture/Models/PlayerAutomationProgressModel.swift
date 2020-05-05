import ReactiveSwift



public enum PlayerAutomationProgressModelState {
    case working(for: Turn)
    case sleeping
}



extension PlayerAutomationProgressModelState: Equatable {}



public protocol PlayerAutomationProgressModelProtocol: class {
    var progressDidChange: ReactiveSwift.Property<PlayerAutomationProgressModelState> { get }
}



public class PlayerAutomationProgressModel: PlayerAutomationProgressModelProtocol {
    public let progressDidChange: ReactiveSwift.Property<PlayerAutomationProgressModelState>


    public init(observing gameModel: GameModelProtocol) {
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
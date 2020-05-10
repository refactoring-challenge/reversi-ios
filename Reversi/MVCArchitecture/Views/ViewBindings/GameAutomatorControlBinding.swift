import ReversiCore
import ReactiveSwift


public class GameAutomatorControlBinding {
    private let gameAutomatorControlHandle: GameAutomatorControlHandleProtocol


    public init(
        observing gameAutomatorAvailabilitiesModel: GameAutomatorAvailabilitiesModelProtocol,
        updating gameAutomatorControlHandle: GameAutomatorControlHandleProtocol
    ) {
        self.gameAutomatorControlHandle = gameAutomatorControlHandle

        // NOTE: Uni-directed data binding to prevent unnecessary events firing.
        gameAutomatorControlHandle.apply(availabilities: gameAutomatorAvailabilitiesModel.availabilities)
    }
}
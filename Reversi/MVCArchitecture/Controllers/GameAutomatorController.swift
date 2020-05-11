import ReversiCore
import ReactiveSwift



public class GameAutomatorController {
    private let gameAutomatorAvailabilitiesModel: GameAutomatorAvailabilitiesModelProtocol
    private let gameAutomatorControlHandle: GameAutomatorControlHandleProtocol
    private let (lifetime, token) = ReactiveSwift.Lifetime.make()


    public init(
        observing gameAutomatorControlHandle: GameAutomatorControlHandleProtocol,
        requestingTo gameAutomatorAvailabilitiesModel: GameAutomatorAvailabilitiesModelProtocol
    ) {
        self.gameAutomatorAvailabilitiesModel = gameAutomatorAvailabilitiesModel
        self.gameAutomatorControlHandle = gameAutomatorControlHandle

        gameAutomatorControlHandle.availabilitiesDidChange
            .take(during: self.lifetime)
            .observe(on: QueueScheduler(qos: .userInteractive))
            .observeValues { [weak self] automationAvailabilities in
                self?.gameAutomatorAvailabilitiesModel.update(availabilities: automationAvailabilities)
            }
    }
}
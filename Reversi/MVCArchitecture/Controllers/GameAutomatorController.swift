import ReversiCore
import ReactiveSwift



public class GameAutomatorController {
    private let model: GameAutomatorAvailabilitiesModelProtocol
    private let (lifetime, token) = ReactiveSwift.Lifetime.make()


    public init(
        observing gameAutomatorAvailabilitiesDidChange: ReactiveSwift.Signal<GameAutomatorAvailabilities, Never>,
        requestingTo model: GameAutomatorAvailabilitiesModelProtocol
    ) {
        self.model = model

        gameAutomatorAvailabilitiesDidChange
            .take(during: self.lifetime)
            .observe(on: QueueScheduler(qos: .userInteractive))
            .observeValues { [weak self] automationAvailabilities in
                self?.model.update(availabilities: automationAvailabilities)
            }
    }
}
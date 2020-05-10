import ReversiCore
import ReactiveSwift



public class BoardAutomationController {
    private let model: GameAutomatorAvailabilitiesModelProtocol
    private let (lifetime, token) = ReactiveSwift.Lifetime.make()


    public init(
        observing firstPlayerAutomationAvailabilityDidChange: ReactiveSwift.Signal<GameAutomatorAvailability, Never>,
        observing secondPlayerAutomationAvailabilityDidChange: ReactiveSwift.Signal<GameAutomatorAvailability, Never>,
        requestingTo model: GameAutomatorAvailabilitiesModelProtocol
    ) {
        self.model = model

        firstPlayerAutomationAvailabilityDidChange
            .take(during: self.lifetime)
            .observe(on: QueueScheduler(qos: .userInteractive))
            .observeValues { [weak self] automationAvailability in
                self?.model.update(availability: automationAvailability, for: .first)
            }

        secondPlayerAutomationAvailabilityDidChange
            .take(during: self.lifetime)
            .observe(on: QueueScheduler(qos: .userInteractive))
            .observeValues { [weak self] automationAvailability in
                self?.model.update(availability: automationAvailability, for: .second)
            }
    }
}
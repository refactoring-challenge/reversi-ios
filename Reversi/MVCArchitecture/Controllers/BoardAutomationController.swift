import ReversiCore
import ReactiveSwift



public class BoardAutomationController {
    private let model: AutomationAvailabilityModelProtocol
    private let (lifetime, token) = ReactiveSwift.Lifetime.make()


    public init(
        observing firstPlayerAutomationAvailabilityDidChange: ReactiveSwift.Signal<AutomationAvailability, Never>,
        observing secondPlayerAutomationAvailabilityDidChange: ReactiveSwift.Signal<AutomationAvailability, Never>,
        requestingTo model: AutomationAvailabilityModelProtocol
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
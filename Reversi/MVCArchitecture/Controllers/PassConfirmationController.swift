import ReversiCore
import ReactiveSwift



public class PassConfirmationController {
    private let model: GameCommandReceivable
    private let (lifetime, token) = ReactiveSwift.Lifetime.make()


    public init(
        observingPassConfirmationDidAccept passConfirmationDidAccept: ReactiveSwift.Signal<Void, Never>,
        requestingTo model: GameCommandReceivable
    ) {
        self.model = model

        passConfirmationDidAccept
            .take(during: self.lifetime)
            .observe(on: QueueScheduler(qos: .userInteractive))
            .observeValues { [weak self] _ in
                self?.model.pass()
            }
    }
}

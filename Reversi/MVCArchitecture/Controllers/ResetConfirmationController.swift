import ReversiCore
import ReactiveSwift



public class ResetConfirmationController {
    private let model: GameCommandReceivable
    private let (lifetime, token) = ReactiveSwift.Lifetime.make()


    public init(
        observingResetConfirmationDidAccept resetConfirmationDidAccept: ReactiveSwift.Signal<Bool, Never>,
        requestingTo model: GameCommandReceivable
    ) {
        self.model = model

        resetConfirmationDidAccept
            .take(during: self.lifetime)
            .observe(on: QueueScheduler(qos: .userInteractive))
            .observeValues { [weak self] isConfirmed in
                guard isConfirmed else { return }
                self?.model.reset()
            }
    }
}

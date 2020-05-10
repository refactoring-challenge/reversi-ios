import ReversiCore
import ReactiveSwift



public class BoardController {
    private let model: GameCommandReceivable
    private let (lifetime, token) = ReactiveSwift.Lifetime.make()


    public init(
        observingPassConfirmationDidAccept passConfirmationDidAccept: ReactiveSwift.Signal<Void, Never>,
        observingResetConfirmationDidAccept resetConfirmationDidAccept: ReactiveSwift.Signal<Bool, Never>,
        requestingTo model: GameCommandReceivable
    ) {
        self.model = model

        passConfirmationDidAccept
            .take(during: self.lifetime)
            .observe(on: QueueScheduler(qos: .userInteractive))
            .observeValues { [weak self] _ in
                self?.model.pass()
            }

        resetConfirmationDidAccept
            .take(during: self.lifetime)
            .observe(on: QueueScheduler(qos: .userInteractive))
            .observeValues { [weak self] isConfirmed in
                guard isConfirmed else { return }
                self?.model.reset()
            }
    }
}

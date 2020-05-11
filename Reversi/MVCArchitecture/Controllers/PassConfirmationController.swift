import ReversiCore
import ReactiveSwift



public class PassConfirmationController {
    private let gameModel: GameCommandReceivable
    private let passConfirmationHandle: PassConfirmationHandleProtocol
    private let (lifetime, token) = ReactiveSwift.Lifetime.make()


    public init(
        observing passConfirmationHandle: PassConfirmationHandleProtocol,
        requestingTo model: GameCommandReceivable
    ) {
        self.gameModel = model
        self.passConfirmationHandle = passConfirmationHandle

        passConfirmationHandle.passDidAccept
            .take(during: self.lifetime)
            .observe(on: QueueScheduler(qos: .userInteractive))
            .observeValues { [weak self] _ in
                self?.gameModel.pass()
            }
    }
}

import ReversiCore
import ReactiveSwift



public class ResetConfirmationController {
    private let gameModel: GameCommandReceivable
    private let resetConfirmationHandle: ResetConfirmationHandleProtocol
    private let (lifetime, token) = ReactiveSwift.Lifetime.make()


    public init(
        observing resetConfirmationHandle: ResetConfirmationHandleProtocol,
        requestingTo model: GameCommandReceivable
    ) {
        self.gameModel = model
        self.resetConfirmationHandle = resetConfirmationHandle

        resetConfirmationHandle.resetDidAccept
            .take(during: self.lifetime)
            .observe(on: QueueScheduler(qos: .userInteractive))
            .observeValues { [weak self] isConfirmed in
                guard isConfirmed else { return }
                self?.gameModel.reset()
            }
    }
}

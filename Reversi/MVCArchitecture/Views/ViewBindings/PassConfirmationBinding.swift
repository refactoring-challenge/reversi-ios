import ReversiCore
import ReactiveSwift



public class PassConfirmationBinding {
    private let gameWithAutomatorsModel: GameWithAutomatorsModelProtocol
    private let passConfirmationHandle: PassConfirmationHandleProtocol
    private let (lifetime, token) = ReactiveSwift.Lifetime.make()


    public init(
        observing gameWithAutomatorsModel: GameWithAutomatorsModelProtocol,
        updating passConfirmationHandle: PassConfirmationHandleProtocol
    ) {
        self.gameWithAutomatorsModel = gameWithAutomatorsModel
        self.passConfirmationHandle = passConfirmationHandle

        gameWithAutomatorsModel.gameWithAutomatorsModelStateDidChange
            .producer
            .take(during: self.lifetime)
            .observe(on: UIScheduler())
            .on(value: { [weak self] state in
                switch state {
                case .mustPlace, .completed, .awaitingReadyOrCompleted, .automatorThinking, .failed:
                    return
                case .mustPass:
                    // BUG18: Alert not appeared because it called before viewDidAppear.
                    self?.passConfirmationHandle.confirm()
                }
            })
            .start()
    }
}
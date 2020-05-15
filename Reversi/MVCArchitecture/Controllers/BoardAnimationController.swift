import ReactiveSwift
import ReversiCore



public class BoardAnimationController {
    private let animatedGameModel: BoardAnimationCommandReceivable
    private let boardAnimationHandle: BoardAnimationHandleProtocol
    private let (lifetime, token) = ReactiveSwift.Lifetime.make()


    public init(
        observing boardAnimationHandle: BoardAnimationHandleProtocol,
        requestingTo animatedGameModel: BoardAnimationCommandReceivable
    ) {
        self.boardAnimationHandle = boardAnimationHandle
        self.animatedGameModel = animatedGameModel

        // BUG16: Initial sync are not applied because markResetAsCompleted was sent before observing.
        boardAnimationHandle.animationDidComplete
            .take(during: self.lifetime)
            .observe(on: QueueScheduler(qos: .userInteractive))
            .observeValues { [weak self] animationRequest in
                switch animationRequest {
                case .shouldAnimate:
                    self?.animatedGameModel.markAnimationAsCompleted()

                case .shouldSyncImmediately:
                    return
                }
            }
    }
}
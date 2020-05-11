import ReactiveSwift
import ReversiCore



public class BoardAnimationController {
    private let boardAnimationModel: BoardAnimationModelProtocol
    private let boardAnimationHandle: BoardAnimationHandleProtocol
    private let (lifetime, token) = ReactiveSwift.Lifetime.make()


    public init(
        observing boardAnimationHandle: BoardAnimationHandleProtocol,
        requestingTo boardAnimationModel: BoardAnimationModelProtocol
    ) {
        self.boardAnimationModel = boardAnimationModel
        self.boardAnimationHandle = boardAnimationHandle

        boardAnimationHandle.animationDidComplete
            .take(during: self.lifetime)
            .observe(on: QueueScheduler(qos: .userInteractive))
            .observeValues { [weak self] animationRequest in
                switch animationRequest {
                case .shouldAnimate:
                    self?.boardAnimationModel.markAnimationAsCompleted()

                case .shouldSyncImmediately:
                    self?.boardAnimationModel.markResetAsCompleted()
                }
            }
    }
}
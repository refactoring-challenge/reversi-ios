import ReactiveSwift
import ReversiCore



public class BoardAnimationController {
    private let boardAnimationModel: BoardAnimationModelProtocol
    private let (lifetime, token) = ReactiveSwift.Lifetime.make()


    public init(
        observingAnimationDidComplete animationDidComplete: ReactiveSwift.Signal<BoardAnimationRequest, Never>,
        requestingTo boardAnimationModel: BoardAnimationModelProtocol
    ) {
        self.boardAnimationModel = boardAnimationModel

        animationDidComplete
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
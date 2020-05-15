import ReactiveSwift
import ReversiCore



public class BoardViewBinding {
    private let animatedGameModel: AnimatedGameModelProtocol
    private let viewHandle: BoardViewHandleProtocol

    private let (lifetime, token) = ReactiveSwift.Lifetime.make()


    public init(
        observing animatedGameModel: AnimatedGameModelProtocol,
        updating viewHandle: BoardViewHandleProtocol
    ) {
        self.animatedGameModel = animatedGameModel
        self.viewHandle = viewHandle

        animatedGameModel
            .animatedGameStateDidChange
            .producer
            .take(during: self.lifetime)
            .observe(on: UIScheduler())
            .on(value: { [weak self] state in
                self?.viewHandle.apply(by: BoardAnimationRequest.of(animationState: state.animationState))
            })
            .start()
    }
}
import ReactiveSwift
import ReversiCore



public class BoardViewBinding {
    private let boardAnimationModel: BoardAnimationModelProtocol
    private let viewHandle: BoardViewHandleProtocol

    private let (lifetime, token) = ReactiveSwift.Lifetime.make()


    public init(
        observing boardAnimationModel: BoardAnimationModelProtocol,
        updating viewHandle: BoardViewHandleProtocol
    ) {
        self.boardAnimationModel = boardAnimationModel
        self.viewHandle = viewHandle

        boardAnimationModel
            .boardAnimationStateDidChange
            .producer
            .take(during: self.lifetime)
            .observe(on: UIScheduler())
            .on(value: { [weak self] state in
                self?.viewHandle.apply(by: state.animationRequest)
            })
            .start()
    }
}
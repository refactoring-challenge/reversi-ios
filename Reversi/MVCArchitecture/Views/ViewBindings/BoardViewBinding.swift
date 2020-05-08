import ReactiveSwift
import ReversiCore



public class BoardViewBinding {
    public let animationDidComplete: ReactiveSwift.Signal<BoardAnimationRequest, Never>
    private let requestDidCompleteObserver: ReactiveSwift.Signal<BoardAnimationRequest, Never>.Observer

    private let boardAnimationModel: BoardAnimationModelProtocol
    private let viewHandle: BoardViewHandleProtocol

    private let (lifetime, token) = ReactiveSwift.Lifetime.make()


    public init(
        observing boardAnimationModel: BoardAnimationModelProtocol,
        updating viewHandle: BoardViewHandleProtocol
    ) {
        self.boardAnimationModel = boardAnimationModel
        self.viewHandle = viewHandle

        (self.animationDidComplete, self.requestDidCompleteObserver) =
            ReactiveSwift.Signal<BoardAnimationRequest, Never>.pipe()

        boardAnimationModel
            .animationStateDidChange
            .producer
            .take(during: self.lifetime)
            .observe(on: UIScheduler())
            .on(value: { [weak self] state in
                guard let self = self else { return }
                guard let animationRequest = state.animationRequest else { return }

                switch animationRequest {
                case .shouldSyncImmediately(board: let board):
                    self.syncImmediately(to: board)

                case .shouldAnimate(disk: let disk, at: let coordinate):
                    self.animate(disk: disk, at: coordinate)
                }
            })
            .start()
    }


    private func syncImmediately(to board: Board) {
        self.viewHandle.cancelAllAnimations()
        self.viewHandle.set(board: board, animated: false) { [weak self] isFinished in
            guard isFinished else { return }
            self?.requestDidCompleteObserver.send(value: .shouldSyncImmediately(board: board))
        }
    }


    private func animate(disk: Disk, at coordinate: Coordinate) {
        self.viewHandle.set(disk: disk, at: coordinate, animated: true) { [weak self] isFinished in
            guard isFinished else { return }
            self?.requestDidCompleteObserver.send(value: .shouldAnimate(disk: disk, at: coordinate))
        }
    }
}
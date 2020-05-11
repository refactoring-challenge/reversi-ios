import ReversiCore
import ReactiveSwift



public class BoardController {
    private let gameModel: GameCommandReceivable
    private let boardViewHandle: BoardViewHandleProtocol
    private let (lifetime, token) = ReactiveSwift.Lifetime.make()


    public init(
        observing boardViewHandle: BoardViewHandleProtocol,
        requestingTo gameModel: GameCommandReceivable
    ) {
        self.gameModel = gameModel
        self.boardViewHandle = boardViewHandle

        boardViewHandle.coordinateDidSelect
            .observe(on: QueueScheduler(qos: .userInitiated))
            .take(during: self.lifetime)
            .observeValues { [weak self] coordinate in
                self?.gameModel.place(at: coordinate)
            }
    }
}
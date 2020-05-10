import ReversiCore
import ReactiveSwift



public class BoardController {
    private let gameModel: GameCommandReceivable
    private let (lifetime, token) = ReactiveSwift.Lifetime.make()


    public init(
        observing coordinateDidSelect: ReactiveSwift.Signal<Coordinate, Never>,
        requestingTo gameModel: GameCommandReceivable
    ) {
        self.gameModel = gameModel

        coordinateDidSelect
            .observe(on: QueueScheduler(qos: .userInitiated))
            .take(during: self.lifetime)
            .observeValues { [weak self] coordinate in
                self?.gameModel.place(at: coordinate)
            }
    }
}
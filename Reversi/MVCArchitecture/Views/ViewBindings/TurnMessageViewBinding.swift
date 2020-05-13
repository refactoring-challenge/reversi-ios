import ReversiCore
import ReactiveSwift



public class TurnMessageViewBinding {
    private let turnViewHandle: TurnMessageViewHandleProtocol
    private let gameModel: GameModelProtocol
    private let (lifetime, token) = ReactiveSwift.Lifetime.make()


    public init(gameModel: GameModelProtocol, updating turnViewHandle: TurnMessageViewHandleProtocol) {
        self.gameModel = gameModel
        self.turnViewHandle = turnViewHandle

        gameModel.gameModelStateDidChange
            .producer
            .take(during: self.lifetime)
            .observe(on: UIScheduler())
            .on(value: { [weak self] gameModelState in
                switch gameModelState {
                case .mustPlace(anywhereIn: _, on: let gameState), .mustPass(on: let gameState):
                    self?.turnViewHandle.apply(message: .inPlay(turn: gameState.turn))
                case .completed(with: let gameResult, on: _):
                    self?.turnViewHandle.apply(message: .completed(result: gameResult))
                }
            })
            .start()
    }
}
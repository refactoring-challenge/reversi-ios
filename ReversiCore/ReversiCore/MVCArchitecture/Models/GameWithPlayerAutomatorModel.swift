import Dispatch
import ReactiveSwift



class GameWithPlayerAutomatorModel {
    let gameModel: GameModelProtocol
    let playersAutomationAvailabilityModel: PlayersAutomationAvailabilityModelProtocol

    private let (lifetime, token) = ReactiveSwift.Lifetime.make()


    convenience init() {
        self.init(
            strategy: PlayerAutomator.randomSelector,
            gameModel: GameModel(startsWith: GameState.initial),
            playersAutomationAvailabilityModel: PlayersAutomationAvailabilityModel(startsWith: .initial)
        )
    }


    init(strategy coordinateSelector: @escaping CoordinateSelector, gameModel: GameModelProtocol, playersAutomationAvailabilityModel: PlayersAutomationAvailabilityModelProtocol) {
        self.gameModel = gameModel
        self.playersAutomationAvailabilityModel = playersAutomationAvailabilityModel

        ReactiveSwift.Property
            .combineLatest(gameModel.stateDidChange, playersAutomationAvailabilityModel.availabilityDidChange)
            .signal
            .take(during: self.lifetime)
            .observeValues { [weak gameModel] in
                guard let gameModel = gameModel else { return }
                let (gameModelState, state) = $0

                switch gameModelState {
                case .processing, .completed:
                    return

                case .ready(let gameState, _):
                    switch state.availability(for: gameState.turn) {
                    case .disabled:
                        return
                    case .enabled:
                        DispatchQueue.global(qos: .background).async {
                            gameModel.next(by: coordinateSelector)
                        }
                    }
                }
            }
    }
}
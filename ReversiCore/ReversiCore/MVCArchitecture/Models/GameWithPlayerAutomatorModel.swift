import Dispatch
import ReactiveSwift


public protocol GameWithPlayerAutomatorModelProtocol: class {
    var gameModel: GameModelProtocol { get }
    var playersAutomationAvailabilityModel: PlayersAutomationAvailabilityModelProtocol { get }
}


public class GameWithPlayerAutomatorModel: GameWithPlayerAutomatorModelProtocol {
    public let gameModel: GameModelProtocol
    public let playersAutomationAvailabilityModel: PlayersAutomationAvailabilityModelProtocol

    private let coordinateSelector: CoordinateSelector
    private let (lifetime, token) = ReactiveSwift.Lifetime.make()


    public convenience init() {
        self.init(
            strategy: PlayerAutomator.delayed(selector: PlayerAutomator.randomSelector, 2.0),
            gameModel: GameModel(startsWith: GameState.initial),
            playersAutomationAvailabilityModel: PlayersAutomationAvailabilityModel(startsWith: .initial)
        )
    }


    public init(
        strategy coordinateSelector: @escaping CoordinateSelector,
        gameModel: GameModelProtocol,
        playersAutomationAvailabilityModel: PlayersAutomationAvailabilityModelProtocol
    ) {
        self.gameModel = gameModel
        self.playersAutomationAvailabilityModel = playersAutomationAvailabilityModel
        self.coordinateSelector = coordinateSelector

        ReactiveSwift.Property
            .combineLatest(gameModel.stateDidChange, playersAutomationAvailabilityModel.availabilityDidChange)
            // BUG8: Signal from Property does not receive the current value at first.
            .producer
            .take(during: self.lifetime)
            .observe(on: QueueScheduler(qos: .background))
            .on { [weak self] in
                guard let self = self else { return }
                let (gameModelState, state) = $0
                self.react(gameModelState: gameModelState, state: state)
            }
            .start()
    }


    private func react(gameModelState: GameModelState, state: PlayersAutomationAvailability) {
        switch gameModelState {
        case .processing, .completed:
            return

        case .ready(let gameState, _):
            switch state.availability(for: gameState.turn) {
            case .disabled:
                return
            case .enabled:
                self.gameModel.next(by: coordinateSelector)
            }
        }
    }
}
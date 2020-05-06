import ReactiveSwift



public enum GameModelState {
    case ready(GameState, Set<AvailableCandidate>)
    case completed(GameState, GameResult)
    case processing(previous: GameState)


    public var gameState: GameState {
        switch self {
        case .processing(previous: let gameState), .completed(let gameState, _), .ready(let gameState, _):
            return gameState
        }
    }


    public static func next(by gameState: GameState) -> GameModelState {
        if let gameResult = gameState.gameResult() {
            return .completed(gameState, gameResult)
        }
        // FIXME: Memoize to prevent calling availableCoordinates because it is expensive.
        return .ready(gameState, gameState.availableCandidates())
    }
}



extension GameModelState: Equatable {}



// NOTE: For testing.
public enum GameModelCommandResult {
    case accepted
    case ignored
}



extension GameModelCommandResult: Equatable {}



public protocol GameModelProtocol: class {
    var stateDidChange: ReactiveSwift.Property<GameModelState> { get }
    var commandDidAccepted: ReactiveSwift.Signal<GameState.AcceptedCommand, Never> { get }

    @discardableResult
    func pass() -> GameModelCommandResult

    @discardableResult
    func place(at: Coordinate) -> GameModelCommandResult

    @discardableResult
    func next(by: CoordinateSelector) -> GameModelCommandResult

    @discardableResult
    func reset() -> GameModelCommandResult
}



public class GameModel: GameModelProtocol {
    public let stateDidChange: ReactiveSwift.Property<GameModelState>
    public let commandDidAccepted: ReactiveSwift.Signal<GameState.AcceptedCommand, Never>

    private let stateDidChangeMutable: ReactiveSwift.MutableProperty<GameModelState>
    private let commandDidAcceptedObserver: ReactiveSwift.Signal<GameState.AcceptedCommand, Never>.Observer

    private var gameModelState: GameModelState {
        get { self.stateDidChangeMutable.value }
        set { self.stateDidChangeMutable.value = newValue }
    }


    public init(initialState: GameModelState) {
        let stateDidChangeMutable = ReactiveSwift.MutableProperty<GameModelState>(initialState)
        self.stateDidChangeMutable = stateDidChangeMutable
        self.stateDidChange = ReactiveSwift.Property(stateDidChangeMutable)

        (self.commandDidAccepted, self.commandDidAcceptedObserver) = ReactiveSwift.Signal<GameState.AcceptedCommand, Never>.pipe()
    }


    public convenience init(startsWith gameState: GameState) {
        self.init(initialState: .next(by: gameState))
    }


    public func pass() -> GameModelCommandResult {
        switch self.gameModelState {
        case .completed, .processing:
            // NOTE: Ignore illegal operations from views.
            return .ignored

        case .ready(let gameState, let availableCoordinates):
            // NOTE: Ignore illegal operations from views.
            guard availableCoordinates.isEmpty else { return .ignored }
            self.gameModelState = .processing(previous: gameState)

            // NOTE: It is safe if the availableCoordinates is calculated on the gameState.
            let (nextGameState, accepted) = gameState.unsafePass()
            self.transit(to: .next(by: nextGameState), by: accepted)
            return .accepted
        }
    }


    public func place(at unsafeCoordinate: Coordinate) -> GameModelCommandResult {
        switch self.gameModelState {
        case .processing, .completed:
            // NOTE: Ignore illegal operations from views.
            return .ignored

        case .ready(let gameState, let availableCoordinates):
            guard let selected = availableCoordinates.first(
                where: { available in available.coordinate == unsafeCoordinate }) else {
                // NOTE: Ignore illegal operations from views.
                return .ignored
            }

            // NOTE: It is safe if the availableCoordinates is calculated on the gameState.
            let (nextGameState, accepted) = gameState.unsafeNext(by: selected)
            self.transit(to: .next(by: nextGameState), by: accepted)
            return .accepted
        }
    }


    public func next(by selector: CoordinateSelector) -> GameModelCommandResult {
        switch self.gameModelState {
        case .processing, .completed:
            // NOTE: Ignore illegal operations from views.
            return .ignored

        case .ready(let gameState, _):
            self.gameModelState = .processing(previous: gameState)

            gameState.next(by: selector)
                .then(in: .background) { [weak self] in
                    guard let self = self else { return }
                    let (nextGameState, accepted) = $0
                    self.transit(to: .next(by: nextGameState), by: accepted)
                }

            return .accepted
        }
    }


    public func reset() -> GameModelCommandResult {
        switch self.gameModelState {
        case .processing:
            return .ignored

        case .ready(let gameState, _), .completed(let gameState, _):
            let (nextGameState, accepted) = gameState.reset()
            self.transit(to: .next(by: nextGameState), by: accepted)
            return .accepted
        }
    }


    private func transit(to nextState: GameModelState, by accepted: GameState.AcceptedCommand) {
        self.gameModelState = nextState
        self.commandDidAcceptedObserver.send(value: accepted)
    }
}

import ReactiveSwift



public protocol GameModelProtocol: GameCommandReceivable {
    var gameModelStateDidChange: ReactiveSwift.Property<GameModelState> { get }
    var gameCommandDidAccepted: ReactiveSwift.Signal<GameState.AcceptedCommand, Never> { get }
}



extension GameModelProtocol {
    public var gameModelState: GameModelState { self.gameModelStateDidChange.value }
}



public class GameModel: GameModelProtocol {
    public let gameModelStateDidChange: ReactiveSwift.Property<GameModelState>
    public let gameCommandDidAccepted: ReactiveSwift.Signal<GameState.AcceptedCommand, Never>

    public private(set) var gameModelState: GameModelState {
        get { self.stateDidChangeMutable.value }
        set { self.stateDidChangeMutable.value = newValue }
    }

    private let stateDidChangeMutable: ReactiveSwift.MutableProperty<GameModelState>
    private let commandDidAcceptedObserver: ReactiveSwift.Signal<GameState.AcceptedCommand, Never>.Observer


    public init(initialState: GameModelState) {
        let stateDidChangeMutable = ReactiveSwift.MutableProperty<GameModelState>(initialState)
        self.stateDidChangeMutable = stateDidChangeMutable
        self.gameModelStateDidChange = ReactiveSwift.Property(stateDidChangeMutable)

        (self.gameCommandDidAccepted, self.commandDidAcceptedObserver) =
            ReactiveSwift.Signal<GameState.AcceptedCommand, Never>.pipe()
    }


    public convenience init(startsWith gameState: GameState) {
        self.init(initialState: .next(by: gameState))
    }


    fileprivate func transit(by accepted: GameState.AcceptedCommand) {
        self.gameModelState = .next(by: accepted.nextGameState)
        self.commandDidAcceptedObserver.send(value: accepted)
    }
}


extension GameModel: GameCommandReceivable {
    public func pass() -> GameCommandResult {
        switch self.gameModelState {
        case .completed:
            // NOTE: Ignore illegal operations from views.
            return .ignored

        case .ready(let gameState, let availableCoordinates):
            // NOTE: Ignore illegal operations from views.
            guard availableCoordinates.isEmpty else { return .ignored }

            // NOTE: It is safe if the availableCoordinates is calculated on the gameState.
            let accepted = gameState.unsafePass()
            self.transit(by: accepted)
            return .accepted
        }
    }


    public func place(at unsafeCoordinate: Coordinate) -> GameCommandResult {
        switch self.gameModelState {
        case .completed:
            // NOTE: Ignore illegal operations from views.
            return .ignored

        case .ready(let gameState, let availableCoordinates):
            guard let selected = availableCoordinates.first(
                where: { available in available.coordinate == unsafeCoordinate }) else {
                // NOTE: Ignore illegal operations from views.
                return .ignored
            }

            // NOTE: It is safe if the availableCoordinates is calculated on the gameState.
            let accepted = gameState.unsafeNext(by: selected)
            self.transit(by: accepted)
            return .accepted
        }
    }


    public func reset() -> GameCommandResult {
        let accepted = self.gameModelState.gameState.reset()
        self.transit(by: accepted)
        return .accepted
    }
}



public enum GameModelState {
    case ready(GameState, Set<AvailableCandidate>)
    case completed(GameState, GameResult)


    public var gameState: GameState {
        switch self {
        case .ready(let gameState, _), .completed(let gameState, _):
            return gameState
        }
    }


    public var availableCandidates: Set<AvailableCandidate> {
        switch self {
        case .ready(_, let availableCandidates):
            return availableCandidates
        case .completed:
            return Set<AvailableCandidate>()
        }
    }


    public var turn: Turn { self.gameState.turn }
    public var board: Board { self.gameState.board }


    public static func initial() -> GameModelState { .next(by: .initial) }


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
public enum GameCommandResult {
    case accepted
    case ignored
}



extension GameCommandResult: Equatable {}

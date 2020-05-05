import ReactiveSwift



public enum GameModelState {
    case ready(GameState, Set<AvailableCoordinate>)
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
        return .ready(gameState, gameState.availableCoordinates())
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


    private let gameModelStateDidChangeMutable: ReactiveSwift.MutableProperty<GameModelState>
    private var gameModelState: GameModelState {
        get { self.gameModelStateDidChangeMutable.value }
        set { self.gameModelStateDidChangeMutable.value = newValue }
    }


    public init(initialState: GameModelState) {
        let gameModelStateDidChangeMutable = ReactiveSwift.MutableProperty<GameModelState>(initialState)
        self.gameModelStateDidChangeMutable = gameModelStateDidChangeMutable
        self.stateDidChange = ReactiveSwift.Property(gameModelStateDidChangeMutable)
    }


    public convenience init(startsWith gameState: GameState) {
        let initialState: GameModelState = .ready(gameState, gameState.availableCoordinates())
        self.init(initialState: initialState)
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
            let nextGameState = gameState.unsafePass()
            self.gameModelState = .next(by: nextGameState)
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
            let nextGameState = gameState.unsafeNext(by: selected)
            self.gameModelState = .next(by: nextGameState)
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
                .then(in: .background) { [weak self] nextGameState in
                    guard let self = self else { return }
                    self.gameModelState = .next(by: nextGameState)
                }

            return .accepted
        }
    }


    public func reset() -> GameModelCommandResult {
        switch self.gameModelState {
        case .processing:
            return .ignored

        case .ready(let gameState, _), .completed(let gameState, _):
            let nextGameState = gameState.reset()
            self.gameModelState = .next(by: nextGameState)
            return .accepted
        }
    }
}

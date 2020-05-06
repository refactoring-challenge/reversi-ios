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
    var linesDidFlip: ReactiveSwift.Signal<NonEmptyArray<Line>, Never> { get }
    var coordinateDidPlace: ReactiveSwift.Signal<Coordinate, Never> { get }

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
    public let linesDidFlip: ReactiveSwift.Signal<NonEmptyArray<Line>, Never>
    public let coordinateDidPlace: ReactiveSwift.Signal<Coordinate, Never>

    private let stateDidChangeMutable: ReactiveSwift.MutableProperty<GameModelState>
    private let linesDidFlipObserver: ReactiveSwift.Signal<NonEmptyArray<Line>, Never>.Observer
    private let coordinateDidPlaceObserver: ReactiveSwift.Signal<Coordinate, Never>.Observer

    private var gameModelState: GameModelState {
        get { self.stateDidChangeMutable.value }
        set { self.stateDidChangeMutable.value = newValue }
    }


    public init(initialState: GameModelState) {
        let stateDidChangeMutable = ReactiveSwift.MutableProperty<GameModelState>(initialState)
        self.stateDidChangeMutable = stateDidChangeMutable
        self.stateDidChange = ReactiveSwift.Property(stateDidChangeMutable)

        (self.linesDidFlip, self.linesDidFlipObserver) = ReactiveSwift.Signal<NonEmptyArray<Line>, Never>.pipe()
        (self.coordinateDidPlace, self.coordinateDidPlaceObserver) = ReactiveSwift.Signal<Coordinate, Never>.pipe()
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

            self.coordinateDidPlaceObserver.send(value: selected.coordinate)
            self.linesDidFlipObserver.send(value: selected.linesWillFlip)

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
                    let (nextGameState, diff) = $0

                    self.gameModelState = .next(by: nextGameState)

                    switch diff {
                    case .passed:
                        return
                    case .placed(by: let selected):
                        self.coordinateDidPlaceObserver.send(value: selected.coordinate)
                        self.linesDidFlipObserver.send(value: selected.linesWillFlip)
                    }
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

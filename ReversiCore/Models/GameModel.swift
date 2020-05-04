import ReactiveSwift



public protocol GameModelProtocol: class {
    var gameStateDidChange: ReactiveSwift.Property<GameState> { get }
    var availableCoordinatesDidChange: ReactiveSwift.Property<Set<Coordinate>> { get }

    func reset()
    func pass()
    func placeDisk(at coordinate: Coordinate)
}



public class GameModel: GameModelProtocol {
    // NOTE: This model has both a turn and board.
    // WHY: Because valid mutable operations to the board is depends on and affect to the turn and it must be
    //      atomic operations. Separating the properties into several smaller models is possible but it cannot
    //      ensure the atomicity without any aggregation wrapper models. And the wrapper model is not needed in
    //      the complexity.
    public let gameStateDidChange: ReactiveSwift.Property<GameState>
    public let availableCoordinatesDidChange: ReactiveSwift.Property<Set<Coordinate>>


    private let gameStateDidChangeMutable: ReactiveSwift.MutableProperty<GameState>
    private var gameState: GameState {
        get { self.gameStateDidChangeMutable.value }
        set { self.gameStateDidChangeMutable.value = newValue }
    }


    public init(startsWith gameState: GameState) {
        let gameStateDidChangeMutable = ReactiveSwift.MutableProperty<GameState>(gameState)
        self.gameStateDidChangeMutable = gameStateDidChangeMutable
        self.gameStateDidChange = ReactiveSwift.Property(gameStateDidChangeMutable)

        self.availableCoordinatesDidChange = gameStateDidChangeMutable
            .map { gameState in gameState.board.availableCoordinates(for: gameState.turn) }
    }


    public func pass() {
        self.gameState = self.gameState.passed()
    }


    public func placeDisk(at coordinate: Coordinate) {
        self.gameState = self.gameState.placed(at: coordinate)
    }


    public func reset() {
        self.gameState = self.gameState.reset()
    }
}
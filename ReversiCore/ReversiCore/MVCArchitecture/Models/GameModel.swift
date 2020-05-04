import ReactiveSwift



protocol GameModelProtocol: class {
    var gameStateDidChange: ReactiveSwift.Property<GameState> { get }
    var availableCoordinatesDidChange: ReactiveSwift.Property<Set<AvailableCoordinate>> { get }
    var gameResultDidChange: ReactiveSwift.Property<GameResult?> { get }

    func pass()
    func place(at: Coordinate)
    func next(by selector: CoordinateSelector)
    func reset()
}



class GameModel: GameModelProtocol {
    let gameStateDidChange: ReactiveSwift.Property<GameState>
    let availableCoordinatesDidChange: ReactiveSwift.Property<Set<AvailableCoordinate>>
    let gameResultDidChange: ReactiveSwift.Property<GameResult?>


    private let gameStateDidChangeMutable: ReactiveSwift.MutableProperty<GameState>
    private var availableCoordinates: Set<AvailableCoordinate> {
        self.gameState.availableCoordinates()
    }
    private var gameState: GameState {
        get { self.gameStateDidChangeMutable.value }
        set { self.gameStateDidChangeMutable.value = newValue }
    }


    init(startsWith gameState: GameState) {
        let gameStateDidChangeMutable = ReactiveSwift.MutableProperty<GameState>(gameState)
        self.gameStateDidChangeMutable = gameStateDidChangeMutable
        self.gameStateDidChange = ReactiveSwift.Property(gameStateDidChangeMutable)

        self.availableCoordinatesDidChange = gameStateDidChangeMutable
            .map { gameState in gameState.availableCoordinates() }
        self.gameResultDidChange = gameStateDidChangeMutable
            .map { gameState in gameState.board.gameResult() }
    }


    func pass() {
        guard self.availableCoordinates.isEmpty else {
            // NOTE: Ignore illegal operations from views.
            return
        }
        self.gameState = self.gameState.unsafePass()
    }


    func place(at coordinate: Coordinate) {
        guard let availableCoordinate = self.getAvailableCoordinate(from: coordinate) else {
            // NOTE: Ignore illegal operations from views.
            return
        }
        self.gameState = self.gameState.unsafeNext(by: availableCoordinate)
    }


    func next(by selector: CoordinateSelector) {
        self.gameState = self.gameState.next(by: selector)
    }


    func reset() {
        self.gameState = self.gameState.reset()
    }


    private func getAvailableCoordinate(from coordinate: Coordinate) -> AvailableCoordinate? {
        self.availableCoordinates
            .filter { available in available.coordinate == coordinate }
            .first
    }
}
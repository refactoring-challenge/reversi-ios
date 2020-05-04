import ReactiveSwift



protocol GameModelProtocol: class {
    var gameStateDidChange: ReactiveSwift.Property<GameState> { get }
    var availableCoordinatesDidChange: ReactiveSwift.Property<Set<Coordinate>> { get }

    func pass()
    func place(at: Coordinate)
    func next(by selector: CoordinateSelector)
    func reset()
}



class GameModel: GameModelProtocol {
    let gameStateDidChange: ReactiveSwift.Property<GameState>
    let availableCoordinatesDidChange: ReactiveSwift.Property<Set<Coordinate>>


    private let gameStateDidChangeMutable: ReactiveSwift.MutableProperty<GameState>
    private var availableCoordinates: Set<GameState.AvailableCoordinate> {
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
            .map { gameState in
            gameState.board.availableCoordinates(for: gameState.turn)
        }
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


    private func getAvailableCoordinate(from coordinate: Coordinate) -> GameState.AvailableCoordinate? {
        self.availableCoordinates
            .filter { available in available.coordinate == coordinate }
            .first
    }
}
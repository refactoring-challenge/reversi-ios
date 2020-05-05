import Hydra


// NOTE: This type has both a turn and board.
// WHY: Because valid mutable operations to the board is depends on and affect to the turn and it must be
//      atomic operations. Separating the properties into several smaller models is possible but it cannot
//      ensure the atomicity without any aggregation wrapper models. And the wrapper model is not needed in
//      the complexity.
struct GameState {
    let board: Board
    let turn: Turn


    static let initial = GameState(board: .initial(), turn: .first)


    func gameResult() -> GameResult? { self.board.gameResult() }


    func availableLines() -> Set<Line> {
        Set(self.board.availableLines(for: self.turn))
    }


    func availableCoordinates() -> Set<AvailableCoordinate> {
        Set(self.board.availableCoordinates(for: self.turn).map(AvailableCoordinate.init(_:)))
    }


    func next(by selector: CoordinateSelector) -> Hydra.Promise<GameState> {
        guard let availableCoordinates = NonEmptyArray(self.availableCoordinates()) else {
            // NOTE: Must pass if no coordinates are available.
            return Hydra.Promise(resolved: self.unsafePass())
        }

        return selector(availableCoordinates)
            .then(in: .background) { selectedAvailableCoordinate -> GameState in
                self.unsafeNext(by: selectedAvailableCoordinate)
            }
    }


    // NOTE: It is unsafe because the available coordinate is possibly no longer available.
    func unsafeNext(by available: AvailableCoordinate) -> GameState {
        let linesShouldBeReplaced = self.availableLines()
            .filter { availableLine in
                availableLine.end == available.coordinate
            }

        var nextBoard = self.board
        for lineShouldBeReplaced in linesShouldBeReplaced {
            nextBoard = nextBoard.unsafeReplaced(with: self.turn.disk, on: lineShouldBeReplaced)
        }
        return GameState(board: nextBoard, turn: self.turn.next)
    }


    // NOTE: It is unsafe because pass may be unavailable.
    func unsafePass() -> GameState {
        GameState(board: self.board, turn: self.turn.next)
    }


    func reset() -> GameState {
        .initial
    }
}



extension GameState: Equatable {}



extension GameState: CustomDebugStringConvertible {
    var debugDescription: String {
        """
        turn: \(self.turn.debugDescription)
        \(self.board.debugDescription)
        """
    }
}



struct AvailableCoordinate {
    let coordinate: Coordinate


    // NOTE: AvailableCoordinate ensures the coordinate is almost valid by hiding initializer.
    //       Only GameState can instantiate AvailableCoordinate.
    fileprivate init(_ coordinate: Coordinate) {
        self.coordinate = coordinate
    }
}



extension AvailableCoordinate: Hashable {}



extension AvailableCoordinate: CustomDebugStringConvertible {
    var debugDescription: String { self.coordinate.debugDescription }
}

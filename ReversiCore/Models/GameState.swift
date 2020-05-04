struct GameState {
    let board: Board
    let turn: Turn


    static let initial = GameState(board: .initial(), turn: .first)


    func availableLines() -> Set<Line> {
        Set(self.board.availableLines(for: self.turn))
    }


    func availableCoordinates() -> Set<AvailableCoordinate> {
        Set(self.board.availableCoordinates(for: self.turn).map(AvailableCoordinate.init(_:)))
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


    func unsafePass() -> GameState {
        GameState(board: self.board, turn: self.turn.next)
    }


    func next(by selector: CoordinateSelector) -> GameState {
        guard let availableCoordinates = NonEmptyArray(self.availableCoordinates()) else {
            // NOTE: Must pass if no coordinates are available.
            return self.unsafePass()
        }

        let selectedAvailableCoordinate = selector(availableCoordinates)
        return self.unsafeNext(by: selectedAvailableCoordinate)
    }


    func reset() -> GameState {
        .initial
    }



    // NOTE: AvailableCoordinate ensures the coordinate is almost valid.
    struct AvailableCoordinate: Hashable {
        let coordinate: Coordinate


        fileprivate init(_ coordinate: Coordinate) {
            self.coordinate = coordinate
        }
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

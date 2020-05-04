struct GameState: Equatable {
    let board: Board
    let turn: Turn


    static let initial = GameState(board: .initial(), turn: .first)


    func availableCoordinates() -> Set<Coordinate> {
        self.board.availableCoordinates(for: self.turn)
    }


    func passed() -> GameState {
        GameState(board: self.board, turn: self.turn.next)
    }


    func placed(at coordinate: Coordinate) -> GameState {
        // PROBLEM: This type unexpectedly accept illegal operations.
        let nextBoard = self.board.updated(value: self.turn.disk, at: coordinate)
        return GameState(board: nextBoard, turn: self.turn.next)
    }


    func reset() -> GameState {
        .initial
    }
}
public struct GameState<L: GameLife>: Equatable {
    public let board: Board


    public static func initial() -> GameState<Zero> { GameState<Zero>(board: .initial()) }


    public func availableCoordinates() -> Set<AvailableLine<L>> {
        Set(self.board.availableLines(for: L.turn).map(AvailableLine<L>.init(_:)))
    }


    public func next(by selector: (NonEmptySet<AvailableLine<L>>) -> AvailableLine<L>) -> GameState<Succ<L>> {
        guard let availableLines = NonEmptySet(self.availableCoordinates()) else {
            // NOTE: It can do only pass
            return GameState<Succ<L>>(board: self.board)
        }

        let selectedLine = selector(availableLines)
        // NOTE: It must be safe because the line is selected on the board in the same game life.
        let nextBoard = self.board.unsafeReplaced(with: L.turn.disk, on: selectedLine.line)
        return GameState<Succ<L>>(board: nextBoard)
    }


    public func reset() -> GameState<Zero> {
        .initial()
    }



    // NOTE: This class has a lifetime type to prevent several illegal operations.
    //       To prohibit illegal operations such as illegal pass or illegal placement,
    //       the AvailableLine can exist if ensured whether the line is available by GameState.
    //       But there is a loophole that using stored old AvailableLine, so a lifetime type is needed to prohibit it.
    public struct AvailableLine<L: GameLife>: Hashable {
        public let line: Line


        fileprivate init(_ line: Line) {
            self.line = line
        }
    }
}
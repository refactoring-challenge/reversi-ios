import Hydra



// NOTE: This type has both a turn and board.
// WHY: Because valid mutable operations to the board is depends on and affect to the turn and it must be
//      atomic operations. Separating the properties into several smaller models is possible but it cannot
//      ensure the atomicity without any aggregation wrapper models. And the wrapper model is not needed in
//      the complexity.
public struct GameState {
    public let board: Board
    public let turn: Turn


    public static let initial = GameState(board: .initial(), turn: .first)


    public init(board: Board, turn: Turn) {
        self.board = board
        self.turn = turn
    }


    public func gameResult() -> GameResult? { self.board.gameResult() }


    public func availableCandidates() -> Set<AvailableCandidate> {
        let availableLines = self.board.availableLines(for: self.turn)
        return AvailableCandidate.from(flippableLines: availableLines)
    }


    public func next(by selector: CoordinateSelector) -> Hydra.Promise<(afterState: GameState, accepted: AcceptedCommand)> {
        guard let availableCandidates = NonEmptyArray(self.availableCandidates()) else {
            // NOTE: Must pass if no coordinates are available.
            return Hydra.Promise(resolved: self.unsafePass())
        }

        return selector(availableCandidates)
            .then(in: .background) { selected in self.unsafeNext(by: selected) }
    }


    // NOTE: It is unsafe because the available coordinate is possibly no longer available.
    public func unsafeNext(by selected: AvailableCandidate) -> (afterState: GameState, accepted: AcceptedCommand) {
        let currentTurn = self.turn
        let nextTurn = self.turn.next

        var nextBoard = self.board
        for shouldBeFlipped in selected.linesShouldFlip.toArray() {
            nextBoard = nextBoard.unsafeReplaced(with: currentTurn.disk, on: shouldBeFlipped.line)
        }

        return (
            afterState: GameState(board: nextBoard, turn: nextTurn),
            accepted: .placed(by: selected, who: currentTurn)
        )
    }


    // NOTE: It is unsafe because pass may be unavailable.
    public func unsafePass() -> (afterState: GameState, accepted: AcceptedCommand) {
        let currentTurn = self.turn
        let nextTurn = self.turn.next
        return (
            afterState: GameState(board: self.board, turn: nextTurn),
            accepted: .passed(who: currentTurn)
        )
    }


    public func reset() -> (afterState: GameState, accepted: AcceptedCommand) {
        (
            afterState: .initial,
            accepted: .reset
        )
    }


    public enum AcceptedCommand {
        case passed(who: Turn)
        case placed(by: AvailableCandidate, who: Turn)
        case reset
    }
}



extension GameState: Equatable {}



extension GameState: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        turn: \(self.turn.debugDescription)
        \(self.board.debugDescription)
        """
    }
}



public struct AvailableCandidate {
    public let coordinate: Coordinate
    public let linesShouldFlip: NonEmptyArray<FlippableLine>


    private init(
        unsafeSelected selectedCoordinate: Coordinate,
        willFlip linesWillFlip: NonEmptyArray<FlippableLine>
    ) {
        self.coordinate = selectedCoordinate
        self.linesShouldFlip = linesWillFlip
    }


    // NOTE: AvailableCoordinate ensures the coordinate is almost valid by hiding initializer.
    //       This is based on only GameState can instantiate AvailableCoordinate.
    fileprivate static func from<Lines: Sequence>(
        flippableLines: Lines
    ) -> Set<AvailableCandidate> where Lines.Element == FlippableLine {
        var result: [Coordinate: NonEmptyArray<FlippableLine>] = [:]

        flippableLines.forEach { flippableLine in
            if let linesWillFlip = result[flippableLine.coordinateToPlace] {
                result[flippableLine.coordinateToPlace] = linesWillFlip.appended(flippableLine)
            }
            else {
                result[flippableLine.coordinateToPlace] = NonEmptyArray<FlippableLine>(first: flippableLine)
                return
            }
        }

        return Set<AvailableCandidate>(result.map {
            let (coordinate, linesWillFlip) = $0
            // NOTE: It is safe because the linesWillFlip must have the coordinate as the end.
            return AvailableCandidate(unsafeSelected: coordinate, willFlip: linesWillFlip)
        })
    }
}



extension AvailableCandidate: Hashable {}



extension AvailableCandidate: CustomDebugStringConvertible {
    public var debugDescription: String { self.coordinate.debugDescription }
}

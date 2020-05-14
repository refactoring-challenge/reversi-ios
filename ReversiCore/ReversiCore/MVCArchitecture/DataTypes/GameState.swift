import Hydra



// NOTE: This type has both a turn and board.
// WHY: Because valid mutable operations to the board is depends on and affect to the turn and it must be
//      atomic operations. Separating the properties into several smaller models is possible but it cannot
//      ensure the atomicity without any aggregation wrapper models. And the wrapper model is not needed in
//      the complexity.
public struct GameState {
    public let board: Board
    public let turn: Turn


    public static let initial = GameState(board: .initial, turn: .first)
    public static let empty = GameState(board: .empty, turn: .first)


    public init(board: Board, turn: Turn) {
        self.board = board
        self.turn = turn
    }


    public func gameResult() -> GameResult? { self.board.gameResult() }


    public func availableCandidates() -> Set<AvailableCandidate> {
        let availableLines = self.board.availableLines(for: self.turn)
        return AvailableCandidate.from(who: self.turn, flippableLines: availableLines)
    }


    // NOTE: It is unsafe because the available coordinate is possibly no longer available.
    public func unsafeNext(by selected: AvailableCandidate) -> AcceptedCommand {
        let currentTurn = self.turn
        let nextTurn = self.turn.next

        var nextBoard = self.board
        selected.linesShouldFlip.forEach { shouldBeFlipped in
            nextBoard = nextBoard.unsafeReplaced(with: currentTurn.disk, on: shouldBeFlipped.line)
        }

        return .placed(with: selected, who: currentTurn, to: GameState(board: nextBoard, turn: nextTurn))
    }


    // NOTE: It is unsafe because pass may be unavailable.
    public func unsafePass() -> AcceptedCommand {
        let currentTurn = self.turn
        let nextTurn = self.turn.next
        return .passed(who: currentTurn, to: GameState(board: self.board, turn: nextTurn))
    }


    public func reset() -> AcceptedCommand {
        .reset(to: .initial)
    }



    public enum AcceptedCommand {
        case passed(who: Turn, to: GameState)
        case placed(with: AvailableCandidate, who: Turn, to: GameState)
        case reset(to: GameState)


        public var nextGameState: GameState {
            switch self {
            case .passed(who: _, to: let nextGameState), .placed(with: _, who: _, to: let nextGameState),
                 .reset(to: let nextGameState):
                return nextGameState
            }
        }
    }
}



extension GameState: Equatable {}



extension GameState: Codable {}



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


    public init(
        unsafeCoordinateToPlace selectedCoordinate: Coordinate,
        willFlipLines linesWillFlip: NonEmptyArray<FlippableLine>
    ) {
        self.coordinate = selectedCoordinate
        self.linesShouldFlip = linesWillFlip
    }


    // NOTE: AvailableCoordinate ensures the coordinate is almost valid by hiding initializer.
    //       This is based on only GameState can instantiate AvailableCoordinate.
    fileprivate static func from<Lines: Sequence>(
        who turn: Turn,
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
            return AvailableCandidate(unsafeCoordinateToPlace: coordinate, willFlipLines: linesWillFlip)
        })
    }
}



extension AvailableCandidate: Hashable {}



extension AvailableCandidate: CustomDebugStringConvertible {
    public var debugDescription: String { self.coordinate.debugDescription }
}



extension AvailableCandidate: CustomReflectable {
    public var customMirror: Mirror { Mirror(reflecting: self.linesShouldFlip) }
}



extension GameState.AcceptedCommand: Equatable {}

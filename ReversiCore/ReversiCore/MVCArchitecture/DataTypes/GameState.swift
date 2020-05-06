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
        return AvailableCandidate.from(availableLines: availableLines)
    }


    public func next(by selector: CoordinateSelector) -> Hydra.Promise<(next: GameState, diff: Diff)> {
        guard let availableCandidates = NonEmptyArray(self.availableCandidates()) else {
            // NOTE: Must pass if no coordinates are available.
            return Hydra.Promise(resolved: (next: self.unsafePass(), diff: .passed))
        }

        return selector(availableCandidates)
            .then(in: .background) { selected -> (next: GameState, diff: Diff) in
                let nextBoard = self.unsafeNext(by: selected)
                return (next: nextBoard, diff: .placed(by: selected))
            }
    }


    // NOTE: It is unsafe because the available coordinate is possibly no longer available.
    public func unsafeNext(by available: AvailableCandidate) -> GameState {
        var nextBoard = self.board
        for lineShouldBeReplaced in available.linesWillFlip.toSequence() {
            nextBoard = nextBoard.unsafeReplaced(with: self.turn.disk, on: lineShouldBeReplaced)
        }
        return GameState(board: nextBoard, turn: self.turn.next)
    }


    // NOTE: It is unsafe because pass may be unavailable.
    public func unsafePass() -> GameState {
        GameState(board: self.board, turn: self.turn.next)
    }


    public func reset() -> GameState {
        .initial
    }



    public enum Diff {
        case passed
        case placed(by: AvailableCandidate)
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



extension GameState.Diff: Equatable {}



public struct AvailableCandidate {
    public let coordinate: Coordinate
    public let linesWillFlip: NonEmptyArray<Line>


    private init(
        unsafeSelected selectedCoordinate: Coordinate,
        willFlip linesWillFlip: NonEmptyArray<Line>
    ) {
        self.coordinate = selectedCoordinate
        self.linesWillFlip = linesWillFlip
    }


    // NOTE: AvailableCoordinate ensures the coordinate is almost valid by hiding initializer.
    //       This is based on only GameState can instantiate AvailableCoordinate.
    fileprivate static func from<Lines: Sequence>(
        availableLines: Lines
    ) -> Set<AvailableCandidate> where Lines.Element == Line {
        var result: [Coordinate: NonEmptyArray<Line>] = [:]

        availableLines.forEach { line in
            if let linesWillFlip = result[line.end] {
                result[line.end] = linesWillFlip.appended(line)
            }
            else {
                result[line.end] = NonEmptyArray<Line>(first: line)
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

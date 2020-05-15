// State transition diagram. Methods not explicitly described are transitions to self.
// The initial state is .notAnimated.
//
//                                                      (initial)
//                                                          |
//                                                          V
//                                                   +--------------+
//                 +-------------------------------->| .notAnimated | <---------------------+
//                 |                                 +------+-------+                       |
//                 |                                        |                               |
//                 |                           .requestAnimation(by: .placed)               |
//     .requestAnimation( by: _)                            |                               |
//                 |                                        V                               |
//                 |                                +---------------+                       |
//                 +--------------------------------| .placing(...) |                       |
//                 A                                +-------+-------+                       |
//                 |                                        |                               |
//                 |                            .markAnimationAsCompleted()                 |
//                 |                                        |                               |
//                 |                                        V                               |
//                 |                                +----------------+                      |
//                 +--------------------------------| .flipping(...) |                      |
//                 A                                +-------+--------+                      |
//                 |                                        |                               |
//                 |                            .markAnimationAsCompleted()                 |
//                 |                                        |                               |
//                 |                                        V                               |
//                 |                                +----------------+                      |
//                 +--------------------------------| .flipping(...) |                      |
//                                                  +-------+--------+                      |
//                                                          |                               |
//                                              .markAnimationAsCompleted()                 |
//                                                          |                               |
//                                                          :                               |
//                                       (repeat until no coordinates remained)             |
//                                                          :                               |
//                                                          |                               |
//                                                          +-------------------------------+
public enum BoardAnimationState {
    case notAnimating(on: Board)
    case placing(at: Coordinate, with: Disk, restLines: NonEmptyArray<FlippableLine>, transaction: BoardAnimationTransaction)
    case flipping(at: Coordinate, with: Disk, restCoordinates: [Coordinate], restLines: [FlippableLine], transaction: BoardAnimationTransaction)


    public var animatingCoordinate: Coordinate? {
        switch self {
        case .notAnimating:
            return nil
        case .placing(at: let coordinate, with: _, restLines: _, transaction: _),
             .flipping(at: let coordinate, with: _, restCoordinates: _, restLines: _, transaction: _):
            return coordinate
        }
    }


    public var isAnimating: Bool {
        switch self {
        case .notAnimating:
            return false
        case .placing, .flipping:
            return true
        }
    }


    public var unfinishedTransaction: BoardAnimationTransaction? {
        switch self {
        case .notAnimating:
            return nil
        case .placing(at: _, with: _, restLines: _, transaction: let transaction),
             .flipping(at: _, with: _, restCoordinates: _, restLines: _, transaction: let transaction):
            return transaction
        }
    }


    public var boardAtThisAnimationEnd: Board {
        switch self {
        case .notAnimating(on: let board):
            return board
        case .placing(at: _, with: _, restLines: _, transaction: let transaction),
             .flipping(at: _, with: _, restCoordinates: _, restLines: _, transaction: let transaction):
            return transaction.end
        }
    }


    /// Next state for animation completions.
    public var nextInTransaction: BoardAnimationState? {
        switch self {
        case .notAnimating:
            // NOTE: Ignore invalid requests.
            return nil

        case .placing(at: _, with: let disk, restLines: let restLines, transaction: let transaction):
            return .flipping(
                lineToFlip: restLines.first,
                disk: disk,
                restLines: restLines.rest,
                inTransaction: transaction
            )

        case .flipping(at: _, with: let disk, restCoordinates: let restCoordinates, restLines: let restLines, transaction: let transaction):
            guard let coordinateToFlip = restCoordinates.first else {
                guard let lineToFlip = restLines.first else {
                    // NOTE: It means that all lines were flipped.
                    return .notAnimating(on: transaction.end)
                }

                // NOTE: It means this line was completed but next lines are remained yet.
                return .flipping(
                    lineToFlip: lineToFlip,
                    disk: disk,
                    restLines: Array(restLines.dropFirst()),
                    inTransaction: transaction
                )
            }

            // NOTE: It means one or more coordinates not flipped is still on this line.
            return .flipping(
                at: coordinateToFlip,
                with: disk,
                restCoordinates: Array(restCoordinates.dropFirst()),
                restLines: restLines,
                transaction: transaction
            )
        }
    }


    public static func beginAnimationTransaction(
        for nextGameModelState: GameModelState,
        lastAnimationState: BoardAnimationState
    ) -> BoardAnimationState {
        guard let lastAcceptedCommand = nextGameModelState.lastAcceptedCommand else {
            // NOTE: This is for when the board was initialized/restored.
            return .initial(board: nextGameModelState.board)
        }
        return .next(lastBoard: lastAnimationState.boardAtThisAnimationEnd, lastAcceptedCommand: lastAcceptedCommand)
    }


    public static func initial(board: Board) -> BoardAnimationState {
        .notAnimating(on: board)
    }


    private static func next(lastBoard: Board, lastAcceptedCommand: GameState.AcceptedCommand) -> BoardAnimationState {
        switch lastAcceptedCommand {
        case .placed(with: let selected, to: let nextGameState):
            return .placing(
                with: selected,
                in: BoardAnimationTransaction(begin: lastBoard, end: nextGameState.board)
            )

        case .passed(who: _, to: let nextGameState):
            return .notAnimating(on: nextGameState.board)

        case .reset(to: let nextGameState):
            return .notAnimating(on: nextGameState.board)
        }
    }


    public static func placing(
        with selected: AvailableCandidate,
        in transaction: BoardAnimationTransaction
    ) -> BoardAnimationState {
        .placing(
            at: selected.coordinate,
            with: selected.turn.disk,
            restLines: selected.linesShouldFlip.sorted(by: lineShouldAnimateBefore),
            transaction: transaction
        )
    }


    private static func flipping(
        lineToFlip: FlippableLine,
        disk: Disk,
        restLines: [FlippableLine],
        inTransaction transaction: BoardAnimationTransaction
    ) -> BoardAnimationState {
        // NOTE: Nearest coordinate from where to place is highest animation priority (see README.md).
        let coordinatesShouldFlipEndToStart = lineToFlip.coordinatesShouldFlipStartToEnd.reversed()
        let coordinateToFlip = coordinatesShouldFlipEndToStart.first
        let restCoordinates = coordinatesShouldFlipEndToStart.rest
        return .flipping(
            at: coordinateToFlip,
            with: disk,
            restCoordinates: restCoordinates,
            restLines: restLines,
            transaction: transaction
        )
    }
}



extension BoardAnimationState: Equatable {}



public func lineShouldAnimateBefore(_ a: FlippableLine, _ b: FlippableLine) -> Bool {
    // NOTE: Do not have to care that both directions of a and b have same priority.
    //       Because flipped lines at a turn cannot not have common directions.
    animationPriority(of: a.line.directedDistance.direction) < animationPriority(of: b.line.directedDistance.direction)
}


public func animationPriority(of direction: Direction) -> Int {
    // SEE: README.md
    // BUG15: This order followed the order in README.md, but the line direction is inverted.
    switch direction {
    case .bottomRight:
        return 0
    case .bottom:
        return 1
    case .bottomLeft:
        return 2
    case .left:
        return 3
    case .topLeft:
        return 4
    case .top:
        return 5
    case .topRight:
        return 6
    case .right:
        return 7
    }
}

import ReactiveSwift



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
public protocol BoardAnimationModelProtocol: class {
    var boardAnimationStateDidChange: ReactiveSwift.Property<BoardAnimationModelState> { get }

    func requestAnimation(by accepted: GameState.AcceptedCommand)

    // NOTE: Why both mark{Animation,Reset}AsCompleted() are needed is to ignore expired animation callbacks.
    func markAnimationAsCompleted()
}



public extension BoardAnimationModelProtocol {
    var boardAnimationState: BoardAnimationModelState { self.boardAnimationStateDidChange.value }
}



public class BoardAnimationModel: BoardAnimationModelProtocol {
    private let (lifetime, token) = ReactiveSwift.Lifetime.make()

    public let boardAnimationStateDidChange: ReactiveSwift.Property<BoardAnimationModelState>
    private let stateDidChangeMutable: ReactiveSwift.MutableProperty<BoardAnimationModelState>

    public private(set) var boardAnimationState: BoardAnimationModelState {
        get { self.stateDidChangeMutable.value }
        set { self.stateDidChangeMutable.value = newValue }
    }


    public init(startsWith board: Board) {
        let stateDidChangeMutable = ReactiveSwift.MutableProperty<BoardAnimationModelState>(.notAnimating(on: board))
        self.stateDidChangeMutable = stateDidChangeMutable
        self.boardAnimationStateDidChange = ReactiveSwift.Property(stateDidChangeMutable)
    }


    public func requestAnimation(by accepted: GameState.AcceptedCommand) {
        switch accepted {
        case .passed:
            // NOTE: Do nothing.
            return

        case .placed(with: let selected, who: let turn, to: let nextGameState):
            self.boardAnimationState = .placing(
                with: selected,
                who: turn,
                // NOTE: Order stop animations and immediately sync to the board that is a result of the last transaction
                //       before starting a new animation transaction. It make the transaction result consistent.
                in: BoardAnimationTransaction(
                    begin: self.boardAnimationState.boardIfTransactionIsDone,
                    end: nextGameState.board
                )
            )

        case .reset:
            self.boardAnimationState = .notAnimating(on: accepted.nextGameState.board)
        }
    }


    public func markAnimationAsCompleted() {
        guard let nextState = self.boardAnimationState.nextInTransaction else { return }
        self.boardAnimationState = nextState
    }
}



public enum BoardAnimationRequest {
    case shouldAnimate(disk: Disk, at: Coordinate, shouldSyncBefore: Board?)
    case shouldSyncImmediately(board: Board)
}



public struct BoardAnimationTransaction {
    let begin: Board
    let end: Board


    public init(begin: Board, end: Board) {
        self.begin = begin
        self.end = end
    }
}



extension BoardAnimationTransaction: Equatable {}



public enum BoardAnimationModelState {
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


    public var unfinishedTransaction: BoardAnimationTransaction? {
        switch self {
        case .notAnimating:
            return nil
        case .placing(at: _, with: _, restLines: _, transaction: let transaction),
             .flipping(at: _, with: _, restCoordinates: _, restLines: _, transaction: let transaction):
            return transaction
        }
    }


    public var boardIfTransactionIsDone: Board {
        switch self {
        case .notAnimating(on: let board):
            return board
        case .placing(at: _, with: _, restLines: _, transaction: let transaction),
             .flipping(at: _, with: _, restCoordinates: _, restLines: _, transaction: let transaction):
            return transaction.end
        }
    }


    public var animationRequest: BoardAnimationRequest {
        switch self {
        case .notAnimating(on: let board):
            return .shouldSyncImmediately(board: board)

        case .placing(at: let coordinate, with: let disk, restLines: _, transaction: let transaction):
            return .shouldAnimate(disk: disk, at: coordinate, shouldSyncBefore: transaction.begin)

        case .flipping(at: let coordinate, with: let disk, restCoordinates: _, restLines: _, transaction: _):
            // BUG17: Should not sync in flipping because both ends of the transaction did not match to transitional boards.
            return .shouldAnimate(disk: disk, at: coordinate, shouldSyncBefore: nil)
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


    /// Next state for animation completions.
    public var nextInTransaction: BoardAnimationModelState? {
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


    public static func placing(
        with selected: AvailableCandidate,
        who turn: Turn,
        in transaction: BoardAnimationTransaction
    ) -> BoardAnimationModelState {
        .placing(
            at: selected.coordinate,
            with: turn.disk,
            restLines: selected.linesShouldFlip.sorted(by: lineShouldAnimateBefore),
            transaction: transaction
        )
    }


    public static func flipping(
        lineToFlip: FlippableLine,
        disk: Disk,
        restLines: [FlippableLine],
        inTransaction transaction: BoardAnimationTransaction
    ) -> BoardAnimationModelState {
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



extension BoardAnimationModelState: Equatable {}



public func lineShouldAnimateBefore(_ a: FlippableLine, _ b: FlippableLine) -> Bool {
    // NOTE: Do not have to care that both directions of a and b have same priority.
    //       Because flipped lines at a turn cannot not have common directions.
    animationPriority(of: a.line.directedDistance.direction) < animationPriority(of: b.line.directedDistance.direction)
}


public func animationPriority(of direction: Direction) -> Int {
    // SEE: README.md
    // BUG15: This order followed the order in README.md, but the line direction is inverted.
    switch direction {
    case .topLeft:
        return 7
    case .top:
        return 6
    case .topRight:
        return 5
    case .right:
        return 4
    case .bottomRight:
        return 3
    case .bottom:
        return 2
    case .bottomLeft:
        return 1
    case .left:
        return 0
    }
}
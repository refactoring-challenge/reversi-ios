import ReactiveSwift



// State transition diagram. Methods not explicitly described are transitions to self.
// The initial state is .notAnimated.
//
//                                                 +-----------------+
//                 +-----------------+-----------> | .resetting(...) |
//                 A                 A             +--------+--------+
//                 |                 |                      |
//                 |                 |           .markResetAsCompleted()
//                 |                 |                      |
//                 |     .requestAnimation(by: .reset)      |    [[ initial ]]
//                 |                 |                      |         /
//                 |                 |                      V        V
//                 |                 |               +--------------+
//                 |                 +---------------| .notAnimated | <---------------------+
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
    func markResetAsCompleted()
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
        let stateDidChangeMutable = ReactiveSwift.MutableProperty<BoardAnimationModelState>(.notAnimating)
        self.stateDidChangeMutable = stateDidChangeMutable
        self.boardAnimationStateDidChange = ReactiveSwift.Property(stateDidChangeMutable)
    }


    public func requestAnimation(by accepted: GameState.AcceptedCommand) {
        switch (self.boardAnimationState, accepted) {
        case (.placing, _), (.flipping, _), (.resetting, _):
            // NOTE: Stop animations and sync immediately to prevent mismatch between BoardModel and BoardView.
            self.boardAnimationState = .resetting(to: accepted.nextGameState.board)

        case (_, .passed):
            // NOTE: Do nothing.
            return

        case (_, .reset):
            self.boardAnimationState = .resetting(to: accepted.nextGameState.board)

        case (.notAnimating, .placed(who: let turn, to: _, by: let selected)):
            self.boardAnimationState = .placing(
                at: selected.coordinate,
                with: turn.disk,
                restLines: selected.linesShouldFlip.sorted(by: shouldAnimateBefore)
            )
        }
    }


    public func markAnimationAsCompleted() {
        guard let nextState = self.boardAnimationState.nextForAnimationCompletion else { return }
        self.boardAnimationState = nextState
    }


    public func markResetAsCompleted() {
        guard let nextState = self.boardAnimationState.nextForResetCompletion else { return }
        self.boardAnimationState = nextState
    }
}



public enum BoardAnimationRequest {
    case shouldAnimate(disk: Disk, at: Coordinate)
    case shouldSyncImmediately(board: Board)
}



public enum BoardAnimationModelState {
    case notAnimating
    case placing(at: Coordinate, with: Disk, restLines: NonEmptyArray<FlippableLine>)
    case flipping(at: Coordinate, with: Disk, restCoordinates: [Coordinate], restLines: [FlippableLine])
    case resetting(to: Board)


    public var animationRequest: BoardAnimationRequest? {
        switch self {
        case .notAnimating:
            return nil
        case .placing(at: let coordinate, with: let disk, restLines: _),
             .flipping(at: let coordinate, with: let disk, restCoordinates: _, restLines: _):
            return .shouldAnimate(disk: disk, at: coordinate)
        case .resetting(to: let board):
            return .shouldSyncImmediately(board: board)
        }
    }


    public var isAnimating: Bool {
        switch self {
        case .notAnimating:
            return false
        case .placing, .flipping, .resetting:
            return true
        }
    }


    /// Next state for reset completions.
    public var nextForResetCompletion: BoardAnimationModelState? {
        switch self {
        case .notAnimating, .placing, .flipping:
            // NOTE: Ignore invalid requests.
            return nil

        case .resetting:
            return .notAnimating
        }
    }


    /// Next state for animation completions.
    public var nextForAnimationCompletion: BoardAnimationModelState? {
        switch self {
        case .notAnimating, .resetting:
            // NOTE: Ignore invalid requests.
            return nil

        case .placing(at: _, with: let disk, restLines: let restLines):
            return .flipping(
                lineToFlip: restLines.first,
                disk: disk,
                restLines: restLines.rest
            )

        case .flipping(at: _, with: let disk, restCoordinates: let restCoordinates, restLines: let restLines):
            guard let coordinateToFlip = restCoordinates.first else {
                guard let lineToFlip = restLines.first else {
                    // NOTE: It means that all lines were flipped.
                    return .notAnimating
                }

                // NOTE: It means this line was completed but next lines are remained yet.
                return .flipping(lineToFlip: lineToFlip, disk: disk, restLines: Array(restLines.dropFirst()))
            }

            // NOTE: It means one or more coordinates not flipped is still on this line.
            return .flipping(
                at: coordinateToFlip,
                with: disk,
                restCoordinates: Array(restCoordinates.dropFirst()),
                restLines: restLines
            )
        }
    }


    public static func flipping(
        lineToFlip: FlippableLine,
        disk: Disk,
        restLines: [FlippableLine]
    ) -> BoardAnimationModelState {
        // NOTE: Nearest coordinate from where to place is highest animation priority (see README.md).
        let coordinatesShouldFlipEndToStart = lineToFlip.coordinatesShouldFlipStartToEnd.reversed()
        let coordinateToFlip = coordinatesShouldFlipEndToStart.first
        let restCoordinates = coordinatesShouldFlipEndToStart.rest
        return .flipping(
            at: coordinateToFlip,
            with: disk,
            restCoordinates: restCoordinates,
            restLines: restLines
        )
    }
}



extension BoardAnimationModelState: Equatable {}



public func shouldAnimateBefore(_ a: FlippableLine, _ b: FlippableLine) -> Bool {
    // NOTE: Do not have to care that both directions of a and b have same priority.
    //       Because flipped lines at a turn cannot not have common directions.
    animationPriority(of: a.line.directedDistance.direction) < animationPriority(of: b.line.directedDistance.direction)
}


public func animationPriority(of direction: Direction) -> Int {
    // SEE: README.md
    switch direction {
    case .topLeft:
        return 0
    case .top:
        return 1
    case .topRight:
        return 2
    case .right:
        return 3
    case .bottomRight:
        return 4
    case .bottom:
        return 5
    case .bottomLeft:
        return 6
    case .left:
        return 7
    }
}
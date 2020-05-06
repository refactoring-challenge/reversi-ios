import ReactiveSwift



public protocol BoardAnimationModelProtocol: class {
    var stateDidChange: ReactiveSwift.Property<BoardAnimationModelState> { get }

    func requestAnimation(to board: Board, by accepted: GameState.AcceptedCommand)
    func markAnimationAsCompleted()
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


    public var request: BoardAnimationRequest? {
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


    public var coordinatesNotAnimatedYet: [Coordinate] {
        switch self {
        case .notAnimating, .resetting:
            return []
        case .placing(at: _, with: _, restLines: let restLines):
            return restLines.flatMap { line in line.coordinatesShouldFlipStartToEnd.toArray() }
        case .flipping(at: _, with: _, restCoordinates: let restCoordinates, restLines: let restLines):
            var coordinates = restCoordinates
            coordinates.append(contentsOf: restLines.flatMap { line in line.coordinatesShouldFlipStartToEnd.toArray() })
            return coordinates
        }
    }


    public var next: BoardAnimationModelState? {
        switch self {
        case .notAnimating:
            return nil

        case .placing(at: _, with: let disk, restLines: let restLines):
            let lineToFlip = restLines.first
            let coordinatesShouldFlipStartToEnd = lineToFlip.coordinatesShouldFlipStartToEnd
            let coordinateToFlip = coordinatesShouldFlipStartToEnd.first
            let restCoordinates = coordinatesShouldFlipStartToEnd.rest

            return .flipping(
                at: coordinateToFlip,
                with: disk,
                restCoordinates: restCoordinates,
                restLines: restLines.rest
            )

        case .flipping(at: _, with: let disk, restCoordinates: let restCoordinates, restLines: let restLines):
            guard let coordinateToFlip = restCoordinates.first else {
                guard let lineToFlip = restLines.first else {
                    // NOTE: It means that all lines were flipped.
                    return .notAnimating
                }

                // NOTE: It means the line was completed but next lines remained.
                let coordinatesShouldFlipStartToEnd = lineToFlip.coordinatesShouldFlipStartToEnd
                let coordinateToFlip = coordinatesShouldFlipStartToEnd.first
                let restCoordinates = coordinatesShouldFlipStartToEnd.rest
                return .flipping(
                    at: coordinateToFlip,
                    with: disk,
                    restCoordinates: restCoordinates,
                    restLines: Array(restLines.dropFirst())
                )
            }

            // NOTE: It means the line has been flipped yet.
            return .flipping(
                at: coordinateToFlip,
                with: disk,
                restCoordinates: Array(restCoordinates.dropFirst()),
                restLines: restLines
            )

        case .resetting:
            return .notAnimating
        }
    }
}



extension BoardAnimationModelState: Equatable {}



public class BoardAnimationModel: BoardAnimationModelProtocol {
    private let (lifetime, token) = ReactiveSwift.Lifetime.make()

    public let stateDidChange: ReactiveSwift.Property<BoardAnimationModelState>
    private let stateDidChangeMutable: ReactiveSwift.MutableProperty<BoardAnimationModelState>

    public let diskShouldUpdate: ReactiveSwift.Signal<BoardAnimationRequest, Never>
    private let diskShouldUpdateObserver: ReactiveSwift.Signal<BoardAnimationRequest, Never>.Observer
    private var state: BoardAnimationModelState {
        get { self.stateDidChangeMutable.value }
        set { self.stateDidChangeMutable.value = newValue }
    }


    public init() {
        let stateDidChangeMutable = ReactiveSwift.MutableProperty<BoardAnimationModelState>(.notAnimating)
        self.stateDidChangeMutable = stateDidChangeMutable
        self.stateDidChange = ReactiveSwift.Property(stateDidChangeMutable)

        (self.diskShouldUpdate, self.diskShouldUpdateObserver
        ) = ReactiveSwift.Signal<BoardAnimationRequest, Never>.pipe()
    }


    public func requestAnimation(to board: Board, by accepted: GameState.AcceptedCommand) {
        switch (self.state, accepted) {
        case (.placing, _), (.flipping, _), (.resetting, _), (_, .reset), (_, .passed):
            self.state = .resetting(to: board)

        case (.notAnimating, .placed(by: let selected, who: let turn)):
            self.state = .placing(
                at: selected.coordinate,
                with: turn.disk,
                restLines: selected.linesShouldFlip.sorted(by: shouldAnimateBefore)
            )
        }
    }


    public func markAnimationAsCompleted() {
        guard let nextState = self.state.next else { return }
        self.state = nextState
    }
}



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
import ReactiveSwift



public protocol GameModelProtocol: AutomatableGameModelProtocol {
    var gameModelStateDidChange: ReactiveSwift.Property<GameModelState> { get }
}



extension GameModelProtocol {
    public var gameModelState: GameModelState { self.gameModelStateDidChange.value }
}



public class GameModel: GameModelProtocol {
    public let gameModelStateDidChange: ReactiveSwift.Property<GameModelState>

    public private(set) var gameModelState: GameModelState {
        get { self.stateDidChangeMutable.value }
        set { self.stateDidChangeMutable.value = newValue }
    }

    private let stateDidChangeMutable: ReactiveSwift.MutableProperty<GameModelState>


    public init(initialState: GameModelState) {
        let stateDidChangeMutable = ReactiveSwift.MutableProperty<GameModelState>(initialState)
        self.stateDidChangeMutable = stateDidChangeMutable
        self.gameModelStateDidChange = ReactiveSwift.Property(stateDidChangeMutable)
    }


    fileprivate func transit(by accepted: GameState.AcceptedCommand) {
        self.gameModelState = .from(for: accepted.nextGameState, lastAcceptedCommand: accepted)
    }
}



extension GameModel: GameCommandReceivable {
    public func pass() -> GameCommandResult {
        switch self.gameModelState {
        case .mustPlace, .completed:
            // NOTE: Ignore illegal operations from views.
            return .ignored

        case .mustPass(on: let gameState, lastAcceptedCommand: _):
            // NOTE: It is safe if the availableCoordinates is calculated on the gameState.
            let accepted = gameState.unsafePass()
            self.transit(by: accepted)
            return .accepted
        }
    }


    public func place(at unsafeCoordinate: Coordinate) -> GameCommandResult {
        switch self.gameModelState {
        case .mustPass, .completed:
            // NOTE: Ignore illegal operations from views.
            return .ignored

        case .mustPlace(anywhereIn: let availableCoordinates, on: let gameState, lastAcceptedCommand: _):
            guard let selected = availableCoordinates.first(
                where: { available in available.coordinate == unsafeCoordinate }) else {
                // NOTE: Ignore illegal operations from views.
                return .ignored
            }

            // NOTE: It is safe if the availableCoordinates is calculated on the gameState.
            let accepted = gameState.unsafeNext(by: selected)
            self.transit(by: accepted)
            return .accepted
        }
    }


    public func reset() -> GameCommandResult {
        let accepted = self.gameModelState.gameState.reset()
        self.transit(by: accepted)
        return .accepted
    }
}



public enum GameModelState {
    case mustPlace(
        anywhereIn: NonEmptyArray<AvailableCandidate>,
        on: GameState,
        lastAcceptedCommand: GameState.AcceptedCommand?
    )
    case mustPass(
        on: GameState,
        lastAcceptedCommand: GameState.AcceptedCommand?
    )
    case completed(
        with: GameResult,
        on: GameState,
        lastAcceptedCommand: GameState.AcceptedCommand?
    )


    public var gameState: GameState {
        switch self {
        case .mustPlace(anywhereIn: _, on: let gameState, lastAcceptedCommand: _),
             .mustPass(on: let gameState, lastAcceptedCommand: _),
             .completed(with: _, on: let gameState, lastAcceptedCommand: _):
            return gameState
        }
    }


    public var availableCandidates: NonEmptyArray<AvailableCandidate>? {
        switch self {
        case .mustPlace(anywhereIn: let availableCandidates, on: _, lastAcceptedCommand: _):
            return availableCandidates
        case .mustPass, .completed:
            return nil
        }
    }


    public var turn: Turn { self.gameState.turn }
    public var board: Board { self.gameState.board }


    public var lastAcceptedCommand: GameState.AcceptedCommand? {
        switch self {
        case .mustPass(on: _, lastAcceptedCommand: let command),
             .mustPlace(anywhereIn: _, on: _, lastAcceptedCommand: let command),
             .completed(with: _, on: _, lastAcceptedCommand: let command):
            return command
        }
    }


    public static let initial = GameModelState.from(for: .initial, lastAcceptedCommand: nil)


    public static func from(
        for gameState: GameState,
        lastAcceptedCommand accepted: GameState.AcceptedCommand?
    ) -> GameModelState {
        if let gameResult = gameState.gameResult() {
            return .completed(with: gameResult, on: gameState, lastAcceptedCommand: accepted)
        }
        // FIXME: Memoize to prevent calling availableCoordinates because it is expensive.
        guard let nonEmptyAvailableCandidates = NonEmptyArray(gameState.availableCandidates()) else {
            return .mustPass(on: gameState, lastAcceptedCommand: accepted)
        }
        return .mustPlace(anywhereIn: nonEmptyAvailableCandidates, on: gameState, lastAcceptedCommand: accepted)
    }
}



extension GameModelState: Equatable {}



// NOTE: For testing.
public enum GameCommandResult {
    case accepted
    case ignored
}



extension GameCommandResult: Equatable {}

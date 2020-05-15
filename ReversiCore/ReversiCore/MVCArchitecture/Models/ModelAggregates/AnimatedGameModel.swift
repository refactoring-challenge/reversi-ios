import ReactiveSwift



public protocol BoardAnimationCommandReceivable: class {
    func markAnimationAsCompleted()
}



public protocol AnimatedGameModelProtocol: BoardAnimationCommandReceivable, AutomatableGameModelProtocol {
    var animatedGameStateDidChange: ReactiveSwift.Property<AnimatedGameModelState> { get }
}



public extension AnimatedGameModelProtocol {
    var animatedGameState: AnimatedGameModelState { self.animatedGameStateDidChange.value }
}



public class AnimatedGameModel: AnimatedGameModelProtocol {
    public let animatedGameStateDidChange: ReactiveSwift.Property<AnimatedGameModelState>
    public let boardAnimationStateDidChange: ReactiveSwift.Property<BoardAnimationState>

    private let gameModel: GameModelProtocol
    private let boardAnimationStateDidChangeMutable: ReactiveSwift.MutableProperty<BoardAnimationState>

    public private(set) var boardAnimationState: BoardAnimationState {
        get { self.boardAnimationStateDidChangeMutable.value }
        set { self.boardAnimationStateDidChangeMutable.value = newValue }
    }
    private let (lifetime, token) = ReactiveSwift.Lifetime.make()


    public init(gameModel: GameModelProtocol) {
        self.gameModel = gameModel

        let initialState: BoardAnimationState = .notAnimating(on: gameModel.gameModelState.board)
        let boardAnimationStateDidChangeMutable = ReactiveSwift.MutableProperty(initialState)
        self.boardAnimationStateDidChangeMutable = boardAnimationStateDidChangeMutable
        self.boardAnimationStateDidChange = ReactiveSwift.Property(boardAnimationStateDidChangeMutable)

        self.animatedGameStateDidChange = boardAnimationStateDidChangeMutable
            .map { boardAnimationState -> AnimatedGameModelState in
                .from(
                    gameModelState: gameModel.gameModelState,
                    animationState: boardAnimationState
                )
            }

        self.start()
    }


    private func start() {
        // BUG10: Did not apply board at BoardView because forgot notify accepted commands to boardAnimationModel.
        gameModel.gameModelStateDidChange
            .producer
            .take(during: self.lifetime)
            .observe(on: QueueScheduler(qos: .userInteractive))
            .on(value: { [weak self] gameModelState in
                guard let self = self else { return }
                self.boardAnimationState = .beginAnimationTransaction(
                    for: gameModelState,
                    lastAnimationState: self.boardAnimationState
                )
            })
            .start()
    }


    public func markAnimationAsCompleted() {
        guard let nextAnimationState = self.boardAnimationState.nextInTransaction else { return }
        self.boardAnimationState = nextAnimationState
    }
}



extension AnimatedGameModel: GameCommandReceivable {
    public func pass() -> GameCommandResult {
        // NOTE: Should not accept any user-initiated command that updating the board during animations except resets.
        guard !self.animatedGameState.isAnimating else { return .ignored }
        return self.gameModel.pass()
    }


    public func place(at coordinate: Coordinate) -> GameCommandResult {
        // NOTE: Should not accept any user-initiated command that updating the board during animations except resets.
        guard !self.animatedGameState.isAnimating else { return .ignored }
        return self.gameModel.place(at: coordinate)
    }


    public func reset() -> GameCommandResult {
        // NOTE: Reset must be accepted during animations (see README.md).
        self.gameModel.reset()
    }
}



public enum AnimatedGameModelState {
    case mustPlace(anywhereIn: NonEmptyArray<AvailableCandidate>, on: GameState, animationState: BoardAnimationState)
    case mustPass(on: GameState, animationState: BoardAnimationState)
    case completed(with: GameResult, on: GameState, animationState: BoardAnimationState)


    public var gameState: GameState {
        switch self {
        case .mustPlace(anywhereIn: _, on: let gameState, animationState: _),
             .mustPass(on: let gameState, animationState: _),
             .completed(with: _, on: let gameState, animationState: _):
            return gameState
        }
    }


    public var availableCandidates: NonEmptyArray<AvailableCandidate>? {
        switch self {
        case .mustPlace(anywhereIn: let availableCandidates, on: _, animationState: _):
            return availableCandidates
        case .mustPass, .completed:
            return nil
        }
    }


    public var turn: Turn { self.gameState.turn }
    public var board: Board { self.gameState.board }


    public var isAnimating: Bool { self.animationState.isAnimating }


    public var animationState: BoardAnimationState {
        switch self {
        case .mustPlace(anywhereIn: _, on: _, animationState: let animationState),
             .mustPass(on: _, animationState: let animationState),
             .completed(with: _, on: _, animationState: let animationState):
            return animationState
        }
    }


    public static func beginAnimationTransaction(
        gameModelState: GameModelState,
        lastAnimationState: BoardAnimationState
    ) -> AnimatedGameModelState {
        let nextAnimationState: BoardAnimationState = .beginAnimationTransaction(
            for: gameModelState,
            lastAnimationState: lastAnimationState
        )

        switch gameModelState {
        case .mustPlace(anywhereIn: let candidates, on: let gameState, lastAcceptedCommand: _):
            return .mustPlace(anywhereIn: candidates, on: gameState, animationState: nextAnimationState)

        case .mustPass(on: let gameState, lastAcceptedCommand: _):
            return .mustPass(on: gameState, animationState: nextAnimationState)

        case .completed(with: let result, on: let gameState, lastAcceptedCommand: _):
            return .completed(with: result, on: gameState, animationState: nextAnimationState)
        }
    }


    public static func from(
        gameModelState: GameModelState,
        animationState: BoardAnimationState
    ) -> AnimatedGameModelState {
        switch gameModelState {
        case .mustPlace(anywhereIn: let candidates, on: let gameState, lastAcceptedCommand: _):
            return .mustPlace(anywhereIn: candidates, on: gameState, animationState: animationState)

        case .mustPass(on: let gameState, lastAcceptedCommand: _):
            return .mustPass(on: gameState, animationState: animationState)

        case .completed(with: let result, on: let gameState, lastAcceptedCommand: _):
            return .completed(with: result, on: gameState, animationState: animationState)
        }
    }
}

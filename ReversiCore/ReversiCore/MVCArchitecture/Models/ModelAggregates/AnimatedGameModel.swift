import ReactiveSwift



public protocol AnimatedGameModelProtocol: BoardAnimationModelProtocol, AutomatableGameModelProtocol {
    var animatedGameStateDidChange: ReactiveSwift.Property<AnimatedGameModelState> { get }
}



public extension AnimatedGameModelProtocol {
    var animatedGameState: AnimatedGameModelState { self.animatedGameStateDidChange.value }
}



public class AnimatedGameModel: AnimatedGameModelProtocol {
    public let animatedGameStateDidChange: ReactiveSwift.Property<AnimatedGameModelState>

    private let gameModel: GameModelProtocol
    private let boardAnimationModel: BoardAnimationModelProtocol
    private let (lifetime, token) = ReactiveSwift.Lifetime.make()


    public init(gameModel: GameModelProtocol, boardAnimationModel: BoardAnimationModelProtocol) {
        self.gameModel = gameModel
        self.boardAnimationModel = boardAnimationModel

        self.animatedGameStateDidChange = ReactiveSwift.Property
            .combineLatest(gameModel.gameModelStateDidChange, boardAnimationModel.boardAnimationStateDidChange)
            .map(AnimatedGameModelState.from(_:))

        // BUG10: Did not apply board at BoardView because forgot notify accepted commands to boardAnimationModel.
        self.start()
    }


    private func start() {
        self.gameModel.gameModelStateDidChange
            .producer
            .take(during: self.lifetime)
            .observe(on: QueueScheduler(qos: .userInitiated))
            .on(value: { [weak self] gameModelState in
                guard let lastAcceptedCommand = gameModelState.lastAcceptedCommand else { return }
                self?.boardAnimationModel.requestAnimation(by: lastAcceptedCommand)
            })
            .start()
    }
}


extension AnimatedGameModel: GameCommandReceivable {
    public func pass() -> GameCommandResult {
        // NOTE: Should not accept any user-initiated command that updating the board during animations except resets.
        guard !self.boardAnimationModel.boardAnimationState.isAnimating else { return .ignored }
        return self.gameModel.pass()
    }


    public func place(at coordinate: Coordinate) -> GameCommandResult {
        // NOTE: Should not accept any user-initiated command that updating the board during animations except resets.
        guard !self.boardAnimationModel.boardAnimationState.isAnimating else { return .ignored }
        return self.gameModel.place(at: coordinate)
    }


    public func reset() -> GameCommandResult {
        // NOTE: Reset must be accepted during animations (see README.md).
        self.gameModel.reset()
    }
}



extension AnimatedGameModel: BoardAnimationModelProtocol {
    public var boardAnimationState: BoardAnimationModelState { self.boardAnimationModel.boardAnimationState }
    public var boardAnimationStateDidChange: ReactiveSwift.Property<BoardAnimationModelState> { self.boardAnimationModel.boardAnimationStateDidChange }


    public func requestAnimation(by accepted: GameState.AcceptedCommand) {
        self.boardAnimationModel.requestAnimation(by: accepted)
    }


    public func markAnimationAsCompleted() {
        self.boardAnimationModel.markAnimationAsCompleted()
    }
}



public enum AnimatedGameModelState {
    case mustPlace(anywhereIn: NonEmptyArray<AvailableCandidate>, on: GameState, isAnimating: Bool)
    case mustPass(on: GameState, isAnimating: Bool)
    case completed(with: GameResult, on: GameState, isAnimating: Bool)


    public var gameState: GameState {
        switch self {
        case .mustPlace(anywhereIn: _, on: let gameState, isAnimating: _),
             .mustPass(on: let gameState, isAnimating: _),
             .completed(with: _, on: let gameState, isAnimating: _):
            return gameState
        }
    }


    public var availableCandidates: NonEmptyArray<AvailableCandidate>? {
        switch self {
        case .mustPlace(anywhereIn: let availableCandidates, on: _, isAnimating: _):
            return availableCandidates
        case .mustPass, .completed:
            return nil
        }
    }


    public var turn: Turn { self.gameState.turn }
    public var board: Board { self.gameState.board }


    public var isAnimating: Bool {
        switch self {
        case .mustPlace(anywhereIn: _, on: _, isAnimating: let isAnimating),
             .mustPass(on: _, isAnimating: let isAnimating),
             .completed(with: _, on: _, isAnimating: let isAnimating):
            return isAnimating
        }
    }


    public static func notAnimating(from gameModelState: GameModelState) -> AnimatedGameModelState {
        switch gameModelState {
        case .mustPlace(anywhereIn: let availableCandidates, on: let gameState, lastAcceptedCommand: _):
            return .mustPlace(anywhereIn: availableCandidates, on: gameState, isAnimating: false)
        case .mustPass(on: let gameState, lastAcceptedCommand: _):
            return .mustPass(on: gameState, isAnimating: false)
        case .completed(with: let gameResult, on: let gameState, lastAcceptedCommand: _):
            return .completed(with: gameResult, on: gameState, isAnimating: false)
        }
    }


    public static func animating(from gameModelState: GameModelState) -> AnimatedGameModelState {
        switch gameModelState {
        case .mustPlace(anywhereIn: let availableCandidates, on: let gameState, lastAcceptedCommand: _):
            return .mustPlace(anywhereIn: availableCandidates, on: gameState, isAnimating: true)
        case .mustPass(on: let gameState, lastAcceptedCommand: _):
            return .mustPass(on: gameState, isAnimating: true)
        case .completed(with: let gameResult, on: let gameState, lastAcceptedCommand: _):
            return .completed(with: gameResult, on: gameState, isAnimating: true)
        }
    }


    public static func from(
        gameModelState: GameModelState,
        animationState: BoardAnimationModelState
    ) -> AnimatedGameModelState {
        animationState.isAnimating
            ? .animating(from: gameModelState)
            : .notAnimating(from: gameModelState)
    }


    public static func from(_ tuple: (gameState: GameModelState, animationState: BoardAnimationModelState)
    ) -> AnimatedGameModelState {
        self.from(gameModelState: tuple.gameState, animationState: tuple.animationState)
    }
}

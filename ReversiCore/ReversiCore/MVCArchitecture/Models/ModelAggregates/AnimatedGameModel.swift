import ReactiveSwift



public protocol AnimatedGameModelProtocol: GameCommandReceivable, BoardAnimationModelProtocol {
    var animatedGameStateDidChange: ReactiveSwift.Property<AnimatedGameModelState> { get }
    var animatedGameCommandDidAccept: ReactiveSwift.Signal<GameState.AcceptedCommand, Never> { get }
}



public extension AnimatedGameModelProtocol {
    var animatedGameState: AnimatedGameModelState { self.animatedGameStateDidChange.value }
}



public class AnimatedGameModel: AnimatedGameModelProtocol {
    public let animatedGameStateDidChange: ReactiveSwift.Property<AnimatedGameModelState>
    public var animatedGameCommandDidAccept: ReactiveSwift.Signal<GameState.AcceptedCommand, Never> {
        self.gameModel.gameCommandDidAccepted
    }

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
        self.gameModel.gameCommandDidAccepted
            .producer
            .take(during: self.lifetime)
            .observe(on: QueueScheduler(qos: .userInitiated))
            .on(value: { [weak self] accepted in
                self?.boardAnimationModel.requestAnimation(by: accepted)
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


    public func markResetAsCompleted() {
        self.boardAnimationModel.markResetAsCompleted()
    }
}



public enum AnimatedGameModelState {
    case ready(GameState, availableCandidates: Set<AvailableCandidate>, isAnimating: Bool)
    case completed(GameState, result: GameResult, isAnimating: Bool)


    public var gameState: GameState {
        switch self {
        case .ready(let gameState, availableCandidates: _, isAnimating: _),
             .completed(let gameState, result: _, isAnimating: _):
            return gameState
        }
    }


    public var availableCandidates: Set<AvailableCandidate> {
        switch self {
        case .ready(_, availableCandidates: let availableCandidates, isAnimating: _):
            return availableCandidates
        case .completed:
            return Set()
        }
    }


    public var turn: Turn { self.gameState.turn }
    public var board: Board { self.gameState.board }


    public var isAnimating: Bool {
        switch self {
        case .ready(_, availableCandidates: _, isAnimating: let isAnimating),
             .completed(_, result: _, isAnimating: let isAnimating):
            return isAnimating
        }
    }


    public static func notAnimating(from gameModelState: GameModelState) -> AnimatedGameModelState {
        switch gameModelState {
        case .ready(let gameState, let availableCandidates):
            return .ready(gameState, availableCandidates: availableCandidates, isAnimating: false)
        case .completed(let gameState, let gameResult):
            return .completed(gameState, result: gameResult, isAnimating: false)
        }
    }


    public static func animating(from gameModelState: GameModelState) -> AnimatedGameModelState {
        switch gameModelState {
        case .ready(let gameState, let availableCandidates):
            return .ready(gameState, availableCandidates: availableCandidates, isAnimating: true)
        case .completed(let gameState, let gameResult):
            return .completed(gameState, result: gameResult, isAnimating: true)
        }
    }


    public static func from(gameModelState: GameModelState, animationState: BoardAnimationModelState
    ) -> AnimatedGameModelState {
        switch animationState {
        case .notAnimating:
            return .notAnimating(from: gameModelState)
        case .placing, .flipping, .resetting:
            return .animating(from: gameModelState)
        }
    }


    public static func from(_ tuple: (gameState: GameModelState, animationState: BoardAnimationModelState)
    ) -> AnimatedGameModelState {
        self.from(gameModelState: tuple.gameState, animationState: tuple.animationState)
    }
}

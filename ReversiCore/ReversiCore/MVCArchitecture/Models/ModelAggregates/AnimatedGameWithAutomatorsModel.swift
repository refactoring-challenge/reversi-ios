import ReactiveSwift



public protocol AnimatedGameWithAutomatorsModelProtocol: BoardAnimationModelProtocol, GameWithAutomatorsModelProtocol {}



public class AnimatedGameWithAutomatorsModel: AnimatedGameWithAutomatorsModelProtocol {
    private let animatedGameModel: AnimatedGameModelProtocol
    private let animatedGameWithAutomatorsModel: GameWithAutomatorsModelProtocol


    public init(
        startsWith initialGameState: GameState,
        automatorAvailabilities: GameAutomatorAvailabilities,
        automatorStrategy: @escaping CoordinateSelector
    ) {
        let animatedGameModel = AnimatedGameModel(
            gameModel: GameModel(startsWith: initialGameState),
            boardAnimationModel: BoardAnimationModel(startsWith: initialGameState.board)
        )
        self.animatedGameModel = animatedGameModel

        self.animatedGameWithAutomatorsModel = GameWithAutomatorsModel(
            automatableGameModel: animatedGameModel,
            automatorModel: GameAutomatorModel(strategy: automatorStrategy),
            automationAvailabilityModel: GameAutomatorAvailabilitiesModel(startsWith: automatorAvailabilities)
        )
    }
}



extension AnimatedGameWithAutomatorsModel: BoardAnimationModelProtocol {
    public var boardAnimationStateDidChange: ReactiveSwift.Property<BoardAnimationModelState> {
        self.animatedGameModel.boardAnimationStateDidChange
    }


    public func requestAnimation(to board: Board, by accepted: GameState.AcceptedCommand) {
        self.animatedGameModel.requestAnimation(to: board, by: accepted)
    }


    public func markAnimationAsCompleted() {
        self.animatedGameModel.markAnimationAsCompleted()
    }


    public func markResetAsCompleted() {
        self.animatedGameModel.markResetAsCompleted()
    }
}



extension AnimatedGameWithAutomatorsModel: GameAutomatorProgressModelProtocol {
    public var automatorDidProgress: ReactiveSwift.Property<GameAutomatorProgress> {
        self.animatedGameWithAutomatorsModel.automatorDidProgress
    }
}



extension AnimatedGameWithAutomatorsModel: GameAutomatorAvailabilitiesModelProtocol {
    public var availabilitiesDidChange: ReactiveSwift.Property<GameAutomatorAvailabilities> {
        self.animatedGameWithAutomatorsModel.availabilitiesDidChange
    }


    public func update(availability: GameAutomatorAvailability, for turn: Turn) {
        self.animatedGameWithAutomatorsModel.update(availability: availability, for: turn)
    }
}



extension AnimatedGameWithAutomatorsModel: GameWithAutomatorsModelProtocol {
    public var gameWithAutomatorsModelStateDidChange: ReactiveSwift.Property<GameWithAutomatorsModelState> {
        self.animatedGameWithAutomatorsModel.gameWithAutomatorsModelStateDidChange
    }


    public func pass() -> GameCommandResult {
        self.animatedGameWithAutomatorsModel.pass()
    }


    public func place(at coordinate: Coordinate) -> GameCommandResult {
        self.animatedGameWithAutomatorsModel.place(at: coordinate)
    }


    public func reset() -> GameCommandResult {
        self.animatedGameWithAutomatorsModel.reset()
    }


    public func cancel() -> GameCommandResult {
        self.animatedGameWithAutomatorsModel.cancel()
    }
}

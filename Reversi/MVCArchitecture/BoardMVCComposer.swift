import UIKitTestable
import ReversiCore



public class BoardMVCComposer {
    private let animatedGameWithAutomatorsModel: AnimatedGameWithAutomatorsModelProtocol
    private let diskCountModel: DiskCountModelProtocol

    private let boardViewBinding: BoardViewBinding
    private let gameAutomatorProgressViewBinding: GameAutomatorProgressViewBinding
    private let gameAutomatorControlBinding: GameAutomatorControlBinding
    private let diskCountViewBinding: DiskCountViewBinding
    private let turnMessageViewBinding: TurnMessageViewBinding

    private let boardController: BoardController
    private let boardAnimationController: BoardAnimationController
    private let gameAutomatorController: GameAutomatorController


    public init(
        boardViewHandle: BoardViewHandleProtocol,
        gameAutomatorProgressViewHandle: GameAutomatorProgressViewHandleProtocol,
        gameAutomatorControlHandle: GameAutomatorControlHandleProtocol,
        passConfirmationViewHandle: PassButtonHandleProtocol,
        resetConfirmationViewHandle: ResetConfirmationViewHandleProtocol,
        diskCountViewHandle: DiskCountViewHandleProtocol,
        turnMessageViewHandle: TurnMessageViewHandle
    ) {
        // STEP-1: Constructing Models and Model Aggregates that are needed by the screen.
        //         And models should be shared across multiple screens will arrive as parameters.
        let animatedGameWithAutomatorsModel = AnimatedGameWithAutomatorsModel(
            startsWith: .initial,
            automatorAvailabilities: .bothDisabled,
            automatorStrategy: GameAutomator.delayed(selector: GameAutomator.randomSelector, 2.0)
        )
        self.animatedGameWithAutomatorsModel = animatedGameWithAutomatorsModel
        self.diskCountModel = DiskCountModel(observing: animatedGameWithAutomatorsModel)

        // STEP-2: Constructing ViewBindings.
        self.boardViewBinding = BoardViewBinding(
            observing: animatedGameWithAutomatorsModel,
            updating: boardViewHandle
        )
        self.gameAutomatorProgressViewBinding = GameAutomatorProgressViewBinding(
            observing: animatedGameWithAutomatorsModel,
            updating: gameAutomatorProgressViewHandle
        )
        let gameAutomatorControlBinding = GameAutomatorControlBinding(
            observing: animatedGameWithAutomatorsModel,
            updating: gameAutomatorControlHandle
        )
        self.gameAutomatorControlBinding = gameAutomatorControlBinding
        self.diskCountViewBinding = DiskCountViewBinding(
            observing: diskCountModel,
            updating: diskCountViewHandle
        )
        self.turnMessageViewBinding = TurnMessageViewBinding(
            gameModel: animatedGameWithAutomatorsModel,
            updating: turnMessageViewHandle
        )

        // STEP-3: Constructing Controllers.
        self.boardController = BoardController(
            observingPassConfirmationDidAccept: passConfirmationViewHandle.passDidAccept,
            observingResetConfirmationDidAccept: resetConfirmationViewHandle.resetDidAccept,
            requestingTo: animatedGameWithAutomatorsModel
        )
        self.boardAnimationController = BoardAnimationController(
            observingAnimationDidComplete: boardViewHandle.animationDidComplete,
            requestingTo: animatedGameWithAutomatorsModel
        )
        self.gameAutomatorController = GameAutomatorController(
            observing: gameAutomatorControlHandle.availabilitiesDidChange,
            requestingTo: animatedGameWithAutomatorsModel
        )
    }
}
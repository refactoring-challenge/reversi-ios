import UIKitTestable
import ReversiCore



public class BoardMVCComposer {
    private let animatedGameWithAutomatorsModel: AnimatedGameWithAutomatorsModelProtocol
    private let diskCountModel: DiskCountModelProtocol

    private let boardViewBinding: BoardViewBinding
    private let playerAutomatorProgressViewBinding: PlayerAutomatorProgressViewBinding
    private let diskCountViewBinding: DiskCountViewBinding

    private let boardController: BoardController
    private let boardAnimationController: BoardAnimationController


    public init(
        boardViewHandle: BoardViewHandleProtocol,
        playerAutomatorProgressViewHandle: PlayerAutomatorProgressViewHandleProtocol,
        passConfirmationViewHandle: PassButtonHandleProtocol,
        resetConfirmationViewHandle: ResetConfirmationViewHandleProtocol,
        diskCountViewHandle: DiskCountViewHandleProtocol
    ) {
        // STEP-1: Constructing Models and Model Aggregates that are needed by the screen.
        //         And models should be shared across multiple screens will arrive as parameters.
        let animatedGameWithAutomatorsModel = AnimatedGameWithAutomatorsModel(
            startsWith: .initial,
            automatorAvailabilities: GameAutomatorAvailabilities(
                first: .disabled,
                second: .disabled
            ),
            automatorStrategy: GameAutomator.delayed(selector: GameAutomator.randomSelector, 2.0)
        )
        self.animatedGameWithAutomatorsModel = animatedGameWithAutomatorsModel
        self.diskCountModel = DiskCountModel(observing: animatedGameWithAutomatorsModel)

        // STEP-2: Constructing ViewBindings.
        self.boardViewBinding = BoardViewBinding(
            observing: animatedGameWithAutomatorsModel,
            updating: boardViewHandle
        )
        self.playerAutomatorProgressViewBinding = PlayerAutomatorProgressViewBinding(
            observing: animatedGameWithAutomatorsModel,
            updating: playerAutomatorProgressViewHandle
        )
        self.diskCountViewBinding = DiskCountViewBinding(
            observing: diskCountModel,
            updating: diskCountViewHandle
        )

        // STEP-3: Constructing Controllers.
        self.boardController = BoardController(
            observingPassConfirmationDidAccept: passConfirmationViewHandle.passDidAccept,
            observingResetConfirmationDidAccept: resetConfirmationViewHandle.resetDidAccept,
            requestingTo: animatedGameWithAutomatorsModel
        )
        self.boardAnimationController = BoardAnimationController(
            observingAnimationDidComplete: boardViewBinding.animationDidComplete,
            requestingTo: animatedGameWithAutomatorsModel
        )
    }
}
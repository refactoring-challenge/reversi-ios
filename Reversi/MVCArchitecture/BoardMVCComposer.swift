import UIKitTestable
import ReversiCore



public class BoardMVCComposer {
    private let animatedGameWithAutomatorsModel: AnimatedGameWithAutomatorsModelProtocol

    private let boardViewBinding: BoardViewBinding
    private let playerAutomatorProgressViewBinding: PlayerAutomatorProgressViewBinding

    private let boardController: BoardController
    private let boardAnimationController: BoardAnimationController


    public init(
        boardViewHandle: BoardViewHandleProtocol,
        playerAutomatorProgressViewHandle: PlayerAutomatorProgressViewHandleProtocol,
        passConfirmationViewHandle: PassButtonHandleProtocol,
        resetConfirmationViewHandle: ResetConfirmationViewHandleProtocol
    ) {
        // STEP-1: Holding Models and Model Decorators that are needed by the screen.
        let animatedGameWithAutomatorsModel = AnimatedGameWithAutomatorsModel(
            startsWith: .initial,
            automatorAvailabilities: GameAutomatorAvailabilities(
                first: .disabled,
                second: .disabled
            ),
            automatorStrategy: GameAutomator.delayed(selector: GameAutomator.randomSelector, 2.0)
        )
        self.animatedGameWithAutomatorsModel = animatedGameWithAutomatorsModel

        // STEP-2: Constructing ViewBindings.
        self.boardViewBinding = BoardViewBinding(
            observing: animatedGameWithAutomatorsModel,
            updating: boardViewHandle
        )
        self.playerAutomatorProgressViewBinding = PlayerAutomatorProgressViewBinding(
            observing: animatedGameWithAutomatorsModel,
            updating: playerAutomatorProgressViewHandle
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
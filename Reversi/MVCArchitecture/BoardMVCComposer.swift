import UIKitTestable
import ReversiCore



public class BoardMVCComposer {
    private let animatedGameWithPlayerAutomationModel: AnimatedGameWithPlayerAutomatorModelProtocol

    private let boardViewBinding: BoardViewBinding
    private let playerAutomatorProgressViewBinding: PlayerAutomatorProgressViewBinding

    private let boardController: BoardController
    private let boardAnimationController: BoardAnimationController


    public init(
        animatedGameWithPlayerAutomationModel: AnimatedGameWithPlayerAutomatorModelProtocol,
        boardViewHandle: BoardViewHandleProtocol,
        playerAutomatorProgressViewHandle: PlayerAutomatorProgressViewHandleProtocol,
        passConfirmationViewHandle: PassButtonHandleProtocol,
        resetConfirmationViewHandle: ResetConfirmationViewHandleProtocol
    ) {
        // STEP-1: Holding Models and Model Decorators that are needed by the screen.
        self.animatedGameWithPlayerAutomationModel = animatedGameWithPlayerAutomationModel

        // STEP-2: Constructing ViewBindings.
        self.boardViewBinding = BoardViewBinding(
            observing: animatedGameWithPlayerAutomationModel,
            updating: boardViewHandle
        )
        self.playerAutomatorProgressViewBinding = PlayerAutomatorProgressViewBinding(
            observing: animatedGameWithPlayerAutomationModel,
            updating: playerAutomatorProgressViewHandle
        )

        // STEP-3: Constructing Controllers.
        self.boardController = BoardController(
            observingPassConfirmationDidAccept: passConfirmationViewHandle.passDidAccept,
            observingResetConfirmationDidAccept: resetConfirmationViewHandle.resetDidAccept,
            requestingTo: animatedGameWithPlayerAutomationModel
        )
        self.boardAnimationController = BoardAnimationController(
            observingAnimationDidComplete: boardViewBinding.animationDidComplete,
            requestingTo: animatedGameWithPlayerAutomationModel
        )
    }
}
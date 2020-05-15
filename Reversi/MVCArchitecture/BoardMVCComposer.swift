import UIKitTestable
import ReversiCore
import ReactiveSwift



public class BoardMVCComposer {
    public let animatedGameWithAutomatorsModel: AnimatedGameWithAutomatorsModelProtocol
    public let diskCountModel: DiskCountModelProtocol

    public let modelTracker: ModelTrackerProtocol

    private let boardViewBinding: BoardViewBinding
    private let gameAutomatorProgressViewBinding: GameAutomatorProgressViewBinding
    private let gameAutomatorControlBinding: GameAutomatorControlBinding
    private let diskCountViewBinding: DiskCountViewBinding
    private let turnMessageViewBinding: TurnMessageViewBinding
    private let passConfirmationBinding: PassConfirmationBinding

    private let passConfirmationController: PassConfirmationController
    private let resetConfirmationController: ResetConfirmationController
    private let boardController: BoardController
    private let boardAnimationController: BoardAnimationController
    private let gameAutomatorController: GameAutomatorController


    public init(
        userDefaults: UserDefaults,
        boardViewHandle: BoardViewHandleProtocol,
        boardAnimationHandle: BoardAnimationHandleProtocol,
        gameAutomatorProgressViewHandle: GameAutomatorProgressViewHandleProtocol,
        gameAutomatorControlHandle: GameAutomatorControlHandleProtocol,
        passConfirmationViewHandle: PassConfirmationHandleProtocol,
        resetConfirmationViewHandle: ResetConfirmationHandleProtocol,
        diskCountViewHandle: DiskCountViewHandleProtocol,
        turnMessageViewHandle: TurnMessageViewHandleProtocol,
        isEventTracesEnabled: Bool = isDebug
    ) {
        #if DEBUG
        let automator = GameAutomator.debuggableDelayed(selector: GameAutomator.randomSelector, duration: 2.0)
        #else
        let automator = GameAutomator.delayed(selector: GameAutomator.randomSelector, duration: 2.0)
        #endif

        // STEP-1: Constructing Models and Model Aggregates that are needed by the screen.
        //         And models should be shared across multiple screens will arrive as parameters.
        let animatedGameWithAutomatorsModel = AnimatedGameWithAutomatorsModel(
            gameModel: AutoBackupGameModel(
                userDefaults: userDefaults,
                defaultValue: .initial
            ),
            gameAutomatorAvailabilitiesModel: AutoBackupGameAutomatorAvailabilitiesModel(
                userDefaults: userDefaults,
                defaultValue: .bothDisabled
            ),
            automatorStrategy: automator
        )
        self.animatedGameWithAutomatorsModel = animatedGameWithAutomatorsModel
        self.diskCountModel = DiskCountModel(observing: animatedGameWithAutomatorsModel)

        // NOTE: This is a Model Tracker that print event traces of Models while the tracker is enabled for
        //       better debugging experience. You can use it via LLDB.
        //
        //       (lldb) po debugModelsHistory()
        self.modelTracker = ModelTracker(
            observing: ReactiveSwift.Property.combineLatest(
                animatedGameWithAutomatorsModel.animatedGameStateDidChange,
                animatedGameWithAutomatorsModel.availabilitiesDidChange,
                animatedGameWithAutomatorsModel.automatorDidProgress,
                animatedGameWithAutomatorsModel.gameModelStateDidChange,
                animatedGameWithAutomatorsModel.automatableGameStateDidChange,
                animatedGameWithAutomatorsModel.gameWithAutomatorsModelStateDidChange
            ),
            isEnabled: isEventTracesEnabled
        )

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
        // BUG14: Forgot binding pass confirmation.
        self.passConfirmationBinding = PassConfirmationBinding(
            observing: animatedGameWithAutomatorsModel,
            updating: passConfirmationViewHandle
        )

        // STEP-3: Constructing Controllers.
        self.boardController = BoardController(
            observing: boardViewHandle,
            requestingTo: animatedGameWithAutomatorsModel
        )
        self.boardAnimationController = BoardAnimationController(
            observing: boardAnimationHandle,
            requestingTo: animatedGameWithAutomatorsModel
        )
        self.passConfirmationController = PassConfirmationController(
            observing: passConfirmationViewHandle,
            requestingTo: animatedGameWithAutomatorsModel
        )
        self.resetConfirmationController = ResetConfirmationController(
            observing: resetConfirmationViewHandle,
            requestingTo: animatedGameWithAutomatorsModel
        )
        self.gameAutomatorController = GameAutomatorController(
            observing: gameAutomatorControlHandle,
            requestingTo: animatedGameWithAutomatorsModel
        )
    }
}
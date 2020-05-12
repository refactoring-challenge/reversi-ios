import UIKit
import UIKitTestable



public class ViewController: UIViewController {
    @IBOutlet private var boardView: BoardView!
    @IBOutlet private var messageDiskView: DiskView!
    @IBOutlet private var messageDiskSizeConstraint: NSLayoutConstraint!
    @IBOutlet private var messageLabel: UILabel!
    @IBOutlet private var countLabels: [UILabel]!
    @IBOutlet private var playerActivityIndicators: [UIActivityIndicatorView]!
    @IBOutlet private var playerControls: [UISegmentedControl]!
    @IBOutlet private var resetButton: UIButton!

    private var composer: BoardMVCComposer?
    private var modalPresenterQueue: ModalPresenterQueueProtocol?


    public override func viewDidLoad() {
        super.viewDidLoad()

        let modalPresenter = UIKitTestable.ModalPresenter(wherePresentOn: .weak(self))
        let modalPresenterQueue = ModalPresenterQueue()
        self.modalPresenterQueue = modalPresenterQueue

        let boardViewHandle = BoardViewHandle(boardView: self.boardView)

        self.composer = BoardMVCComposer(
            userDefaults: UserDefaults.standard,
            boardViewHandle: boardViewHandle,
            boardAnimationHandle: boardViewHandle,
            gameAutomatorProgressViewHandle: GameAutomatorProgressViewHandle(
                firstActivityIndicator: self.playerActivityIndicators[0],
                secondActivityIndicator: self.playerActivityIndicators[1]
            ),
            gameAutomatorControlHandle: GameAutomatorControlHandle(
                firstSegmentedControl: self.playerControls[0],
                secondSegmentedControl: self.playerControls[1]
            ),
            passConfirmationViewHandle: PassConfirmationHandle(
                willModalsPresentOn: modalPresenter,
                orEnqueueIfViewNotAppeared: modalPresenterQueue
            ),
            resetConfirmationViewHandle: ResetConfirmationHandle(
                button: self.resetButton,
                willModalsPresentOn: modalPresenter,
                orEnqueueIfViewNotAppeared: modalPresenterQueue
            ),
            diskCountViewHandle: DiskCountViewHandle(
                firstPlayerCountLabel: self.countLabels[0],
                secondPlayerCountLabel: self.countLabels[1]
            ),
            turnMessageViewHandle: TurnMessageViewHandle(
                messageLabel: self.messageLabel,
                messageDiskView: self.messageDiskView,
                messageDiskViewConstraint: self.messageDiskSizeConstraint
            )
        )
    }


    public override func viewDidAppear(_ animated: Bool) {
        self.modalPresenterQueue?.viewDidAppear()
    }


    public override func viewWillDisappear(_ animated: Bool) {
        self.modalPresenterQueue?.viewWillDisappear()
    }
}

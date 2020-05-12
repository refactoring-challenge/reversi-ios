import UIKit
import UIKitTestable
import ReactiveSwift



public protocol ResetConfirmationHandleProtocol {
    var resetDidAccept: ReactiveSwift.Signal<Bool, Never> { get }
}



public class ResetConfirmationHandle: ResetConfirmationHandleProtocol {
    private let confirmationViewHandle: UserConfirmationViewHandle<Bool>
    private let button: UIButton


    public let resetDidAccept: ReactiveSwift.Signal<Bool, Never>


    public init(
        button: UIButton,
        willModalsPresentOn modalPresenter: UIKitTestable.ModalPresenterProtocol,
        orEnqueueIfViewNotAppeared modalPresenterQueue: ModalPresenterQueueProtocol
    ) {
        self.button = button

        let confirmationViewHandle = UserConfirmationViewHandle(
            title: "Confirmation",
            message: "Do you really want to reset the game?",
            preferredStyle: .alert,
            actions: [
                (title: "Cancel", style: .cancel, false),
                // BUG13: Unexpectedly use false instead of true.
                (title: "OK", style: .default, true),
            ],
            willPresentOn: modalPresenter,
            orEnqueueIfViewNotAppeared: modalPresenterQueue
        )
        self.confirmationViewHandle = confirmationViewHandle
        self.resetDidAccept = self.confirmationViewHandle.userDidConfirm

        button.addTarget(self, action: #selector(self.confirm(_:)), for: .touchUpInside)
    }


    @objc private func confirm(_ sender: Any) {
        self.confirmationViewHandle.confirm()
    }
}

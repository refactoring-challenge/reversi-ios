import UIKit
import UIKitTestable
import ReactiveSwift



public protocol ResetConfirmationViewHandleProtocol {
    var resetDidAccept: ReactiveSwift.Signal<Bool, Never> { get }
    func confirm()
}



public class ResetConfirmationViewHandle: ResetConfirmationViewHandleProtocol {
    private let confirmationViewHandle: UserConfirmationViewHandle<Bool>


    public let resetDidAccept: ReactiveSwift.Signal<Bool, Never>


    public init(willPresentOn modalPresenter: UIKitTestable.ModalPresenterProtocol) {
        let confirmationViewHandle = UserConfirmationViewHandle(
            title: "Confirmation",
            message: "Do you really want to reset the game?",
            preferredStyle: .alert,
            actions: [
                (title: "Cancel", style: .cancel, false),
                (title: "OK", style: .default, false),
            ],
            willPresentOn: modalPresenter
        )
        self.confirmationViewHandle = confirmationViewHandle
        self.resetDidAccept = self.confirmationViewHandle.userDidConfirm
    }


    public func confirm() {
        self.confirmationViewHandle.confirm()
    }
}

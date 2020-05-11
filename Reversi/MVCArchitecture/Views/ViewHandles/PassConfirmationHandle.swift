import UIKit
import UIKitTestable
import ReactiveSwift



public protocol PassConfirmationHandleProtocol {
    var passDidAccept: ReactiveSwift.Signal<Void, Never> { get }
    func confirm()
}



public class PassConfirmationHandle: PassConfirmationHandleProtocol {
    public let passDidAccept: ReactiveSwift.Signal<Void, Never>

    private let confirmationViewHandle: UserConfirmationViewHandle<Void>


    public init(willModalsPresentOn modalPresenter: UIKitTestable.ModalPresenterProtocol) {
        let confirmationViewHandle = UserConfirmationViewHandle(
            title: "Pass",
            message: "Cannot place a disk.",
            preferredStyle: .alert,
            actions: [(title: "Dismiss", style: .default, ())],
            willPresentOn: modalPresenter
        )
        self.confirmationViewHandle = confirmationViewHandle
        self.passDidAccept = self.confirmationViewHandle.userDidConfirm
    }


    public func confirm() {
        self.confirmationViewHandle.confirm()
    }
}

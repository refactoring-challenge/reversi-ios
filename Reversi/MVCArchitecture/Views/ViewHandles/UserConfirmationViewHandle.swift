import UIKit
import UIKitTestable
import ReactiveSwift



public protocol UserConfirmationViewHandleProtocol {
    associatedtype Choice
    var userDidConfirm: ReactiveSwift.Signal<Choice, Never> { get }
    func confirm()
}



extension UserConfirmationViewHandleProtocol {
    public func asAny() -> AnyUserConfirmationViewHandle<Choice> { AnyUserConfirmationViewHandle(self) }
}



public class UserConfirmationViewHandle<T>: UserConfirmationViewHandleProtocol {
    public let userDidConfirm: ReactiveSwift.Signal<T, Never>
    private let userDidConfirmObserver: ReactiveSwift.Signal<T, Never>.Observer
    private let title: String
    private let message: String
    private let preferredStyle: UIAlertController.Style
    private let actions: [(title: String, style: UIAlertAction.Style, value: T)]
    private let modalPresenter: UIKitTestable.ModalPresenterProtocol
    private let modalPresenterQueue: ModalPresenterQueueProtocol


    public init(
        title: String,
        message: String,
        preferredStyle: UIAlertController.Style,
        actions: [(title: String, style: UIAlertAction.Style, value: T)],
        willPresentOn modalPresenter: UIKitTestable.ModalPresenterProtocol,
        orEnqueueIfViewNotAppeared modalPresenterQueue: ModalPresenterQueueProtocol
    ) {
        self.title = title
        self.message = message
        self.actions = actions
        self.preferredStyle = preferredStyle
        self.modalPresenter = modalPresenter
        self.modalPresenterQueue = modalPresenterQueue

        (self.userDidConfirm, self.userDidConfirmObserver) = ReactiveSwift.Signal<T, Never>.pipe()
    }


    public func confirm() {
        let alertViewController = UIAlertController(
            title: self.title,
            message: self.message,
            preferredStyle: self.preferredStyle
        )

        self.actions.forEach { action in
            alertViewController.addAction(UIAlertAction(
                title: action.title,
                style: action.style,
                handler: { [weak self] _ in
                    self?.userDidConfirmObserver.send(value: action.value)
                })
            )
        }

        self.modalPresenterQueue.enqueue(task: ModalPresenterTask(
            modalPresenter: self.modalPresenter,
            modalViewControllerRef: .strong(alertViewController),
            animated: true
        ))
    }
}



public struct AnyUserConfirmationViewHandle<Choice>: UserConfirmationViewHandleProtocol {
    private let _userDidConfirm: () -> ReactiveSwift.Signal<Choice, Never>
    private let _confirm: () -> Void


    public init<P: UserConfirmationViewHandleProtocol>(_ viewHandle: P) where P.Choice == Choice {
        self._userDidConfirm = { viewHandle.userDidConfirm }
        self._confirm = { viewHandle.confirm() }
    }


    public var userDidConfirm: Signal<Choice, Never> { self._userDidConfirm() }


    public func confirm() { self._confirm() }
}

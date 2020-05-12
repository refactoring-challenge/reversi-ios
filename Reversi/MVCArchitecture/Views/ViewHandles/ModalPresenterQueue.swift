import UIKitTestable



public protocol ModalPresenterQueueProtocol {
    func enqueue(task: ModalPresenterTask)
    func viewDidAppear()
    func viewWillDisappear()
}



public struct ModalPresenterTask {
    private let modalPresenter: ModalPresenterProtocol
    private let modalViewControllerRef: WeakOrUnownedOrStrong<UIViewController>
    private let animated: Bool
    private let completion: (() -> Void)?


    public init(
        modalPresenter: ModalPresenterProtocol,
        modalViewControllerRef: WeakOrUnownedOrStrong<UIViewController>,
        animated: Bool,
        completion: (() -> Void)? = nil
    ) {
        self.modalPresenter = modalPresenter
        self.modalViewControllerRef = modalViewControllerRef
        self.animated = animated
        self.completion = completion
    }


    public func start() {
        switch self.modalViewControllerRef {
        case .strongReference(let strongRef):
            strongRef.do(self.present)

        case .weakReference(let weakRef):
            weakRef.do(self.present)

        case .unownedReference(let unownedRef):
            unownedRef.do(self.present)
        }
    }


    private func present(viewController: UIViewController?) {
        guard let viewController = viewController else { return }
        self.modalPresenter.present(
            viewController: viewController,
            animated: self.animated,
            completion: self.completion
        )
    }
}



public class ModalPresenterQueue: ModalPresenterQueueProtocol {
    private var isAppearing: Bool = false
    private var queue = [ModalPresenterTask]()


    public func enqueue(task: ModalPresenterTask) {
        guard self.isAppearing else {
            self.queue.append(task)
            return
        }

        task.start()
    }


    public func viewDidAppear() {
        self.isAppearing = true

        let queue = self.queue
        self.queue.removeAll()

        queue.forEach { task in task.start() }
    }


    public func viewWillDisappear() {
        self.isAppearing = false
    }
}
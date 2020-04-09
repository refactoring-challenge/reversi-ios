import Foundation

final class Canceller {
    typealias CleanUp = () -> Void
    private(set) var isCancelled: Bool = false
    private let cleanUp: CleanUp?

    init(_ cleanUp: CleanUp?) {
        self.cleanUp = cleanUp
    }

    func cancel() {
        if isCancelled { return }
        isCancelled = true
        cleanUp?()
    }
}

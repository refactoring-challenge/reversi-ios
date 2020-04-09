import Foundation

public final class Canceller {
    public typealias CleanUp = () -> Void
    public private(set) var isCancelled: Bool = false
    private let cleanUp: CleanUp?

    init(_ cleanUp: CleanUp?) {
        self.cleanUp = cleanUp
    }

    public func cancel() {
        if isCancelled { return }
        isCancelled = true
        cleanUp?()
    }
}

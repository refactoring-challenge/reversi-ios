import Foundation

final class ThinkingOfComputerState {
    private var thinkingCanceller: Canceller?
    var isThinking: Bool { thinkingCanceller != nil }
    var isCancelled: Bool {
        guard let canceller = thinkingCanceller else { return false }
        return canceller.isCancelled
    }

    @discardableResult
    func createThinkingCanceller(at side: Disk? = nil, cleanUp: Canceller.CleanUp? = nil) -> Canceller {
        let cleanUpWrapper: Canceller.CleanUp = { [weak self] in
            cleanUp?()
            self?.thinkingCanceller = nil
        }
        let canceller = Canceller(cleanUpWrapper)
        thinkingCanceller = canceller
        return canceller
    }

    func cancel() {
        thinkingCanceller?.cancel()
        thinkingCanceller = nil
    }
}

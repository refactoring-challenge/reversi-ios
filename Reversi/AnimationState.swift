import Foundation

final class AnimationState {
    typealias CleanUp = () -> Void
    final class Canceller {
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

    private var animationCanceller: Canceller?
    var isAnimating: Bool { animationCanceller != nil }
    var isCancelled: Bool {
        guard let canceller = animationCanceller else { return false }
        return canceller.isCancelled
    }

    private var playerCancellers: [Disk: Canceller] = [:]

    @discardableResult
    func createAnimationCanceller(at side: Disk? = nil, cleanUp: CleanUp? = nil) -> Canceller {
        switch side {
        case .some(let side):
            let cleanUpWrapper: CleanUp = { [weak self] in
                cleanUp?()
                self?.playerCancellers[side] = nil
            }
            let canceller = Canceller(cleanUpWrapper)
            playerCancellers[side] = canceller
            return canceller
        case .none:
            let cleanUpWrapper: CleanUp = { [weak self] in
                cleanUp?()
                self?.animationCanceller = nil
            }
            let canceller = Canceller(cleanUpWrapper)
            animationCanceller = canceller
            return canceller
        }
    }

    func cancel(at side: Disk? = nil) {
        switch side {
        case .some(let side):
            playerCancellers[side]?.cancel()
        case .none:
            animationCanceller?.cancel()
        }
    }

    func cancelAll() {
        animationCanceller?.cancel()
        animationCanceller = nil

        for side in Disk.sides {
            playerCancellers[side]?.cancel()
            playerCancellers.removeValue(forKey: side)
        }
    }
}

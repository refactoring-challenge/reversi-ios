import Foundation

public final class AnimationState {
    private var animationCanceller: Canceller?
    public var isAnimating: Bool { animationCanceller != nil }
    public var isCancelled: Bool {
        guard let canceller = animationCanceller else { return false }
        return canceller.isCancelled
    }

    private var playerCancellers: [Disk: Canceller] = [:]

    public init() {
    }

    @discardableResult
    public func createAnimationCanceller(at side: Disk? = nil, cleanUp: Canceller.CleanUp? = nil) -> Canceller {
        switch side {
        case .some(let side):
            let cleanUpWrapper: Canceller.CleanUp = { [weak self] in
                cleanUp?()
                self?.playerCancellers[side] = nil
            }
            let canceller = Canceller(cleanUpWrapper)
            playerCancellers[side] = canceller
            return canceller
        case .none:
            let cleanUpWrapper: Canceller.CleanUp = { [weak self] in
                cleanUp?()
                self?.animationCanceller = nil
            }
            let canceller = Canceller(cleanUpWrapper)
            animationCanceller = canceller
            return canceller
        }
    }

    public func cancel(at side: Disk? = nil) {
        switch side {
        case .some(let side):
            playerCancellers[side]?.cancel()
        case .none:
            animationCanceller?.cancel()
        }
    }

    public func cancelAll() {
        animationCanceller?.cancel()
        animationCanceller = nil

        for side in Disk.sides {
            playerCancellers[side]?.cancel()
            playerCancellers.removeValue(forKey: side)
        }
    }
}

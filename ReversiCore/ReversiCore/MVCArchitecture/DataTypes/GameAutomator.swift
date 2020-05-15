import Foundation
import Hydra



public enum GameAutomator {
    // NOTE: Prohibit illegal pass because players cannot pass if one or more available coordinate exist.
    public static let randomSelector: CoordinateSelector = { availableCoordinates in
        Hydra.Promise(resolved: availableCoordinates.randomElement())
    }


    public static func delayed(selector: @escaping CoordinateSelector, duration: TimeInterval) -> CoordinateSelector {
        { availableCoordinates in selector(availableCoordinates).defer(in: .utility, duration) }
    }


    public static let topLeftSelector: CoordinateSelector = { availableCoordinates in
        let selected = availableCoordinates
            .rest
            .reduce(availableCoordinates.first) { minAvailable, available in minCoordinate(minAvailable, available) }

        return Hydra.Promise(resolved: selected)
    }


    public static let pendingSelector: CoordinateSelector = { _ in
        Hydra.Promise { _, _, _ in }
    }


    #if DEBUG
    public static var debugDuration: TimeInterval = 0


    /// - Example: `(lldb) po debugFastThinking()`
    public static func debuggableDelayed(
        selector: @escaping CoordinateSelector,
        duration: TimeInterval
    ) -> CoordinateSelector {
        GameAutomator.debugDuration = duration
        return { availableCandidates in
            GameAutomator.delayed(selector: selector, duration: GameAutomator.debugDuration)(availableCandidates)
        }
    }
    #else
    public static let debugDuration: TimeInterval = 0
    #endif
}



private func minCoordinate(_ a: AvailableCandidate, _ b: AvailableCandidate) -> AvailableCandidate {
    let aIndex = coordinateIndex(a.coordinate)
    let bIndex = coordinateIndex(b.coordinate)
    return aIndex == bIndex
        ? a
        : aIndex < bIndex
        ? a
        : b
}


private func coordinateIndex(_ coordinate: Coordinate) -> Int {
    (coordinate.x.rawValue - 1) + (coordinate.y.rawValue - 1) * 8
}

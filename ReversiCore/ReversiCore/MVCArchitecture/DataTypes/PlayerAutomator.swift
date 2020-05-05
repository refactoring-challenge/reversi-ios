import Hydra
import Foundation



enum PlayerAutomator {
    // NOTE: Prohibit illegal pass because players cannot pass if one or more available coordinate exist.
    static let randomSelector: CoordinateSelector = { availableCoordinates in
        Hydra.Promise(resolved: availableCoordinates.randomElement())
    }


    static func delayed(selector: @escaping CoordinateSelector, _ duration: TimeInterval) -> CoordinateSelector {
        { availableCoordinates in selector(availableCoordinates).defer(in: .background, duration) }
    }


    static let topLeftSelector: CoordinateSelector = { availableCoordinates in
        let selected = availableCoordinates
            .rest
            .reduce(availableCoordinates.first) { minAvailable, available in
                minCoordinate(minAvailable, available)
            }

        return Hydra.Promise(resolved: selected)
    }


    static let pendingSelector: CoordinateSelector = { _ in
        Hydra.Promise { _, _, _ in }
    }
}



private func minCoordinate(_ a: AvailableCoordinate, _ b: AvailableCoordinate) -> AvailableCoordinate {
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

public enum GameCommand: Equatable {
    case pass
    case place(at: Coordinate)


    public func unsafeExecute(on gameState: GameState) -> GameState {
        let availableCoordinates = gameState.availableCoordinates()

        switch self {
        case .pass:
            guard availableCoordinates.isEmpty else {
                fatalError("GameCommand: Cannot pass because available coordinates exist:\n\(formatCoordinate(availableCoordinates))")
            }
            return gameState.passed()

        case .place(at: let coordinate):
            guard availableCoordinates.contains(coordinate) else {
                fatalError("GameCommand: Cannot place at {\(coordinate)} because it is not available:\n\(formatCoordinate(availableCoordinates))")
            }
            return gameState.placed(at: coordinate)
        }
    }
}


private func formatCoordinate<S: Sequence>(_ coordinates: S) -> String where S.Element == Coordinate {
    coordinates
        .map { "\t\($0.debugDescription)" }
        .joined(separator: "\n")
}
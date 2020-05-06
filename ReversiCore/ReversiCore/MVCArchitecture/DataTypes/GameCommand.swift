public enum GameCommand {
    case pass
    case place(at: Coordinate)



    public enum PreconditionFailure: Error {
        case cannotPass(on: GameState)
        case cannotPlace(at: Coordinate, on: GameState)
    }



    public func unsafeExecute(on gameState: GameState) throws -> GameState {
        switch self {
        case .pass:
            guard gameState.availableCandidates().isEmpty else {
                throw PreconditionFailure.cannotPass(on: gameState)
            }
            return gameState.unsafePass().afterState

        case .place(at: let coordinate):
            guard let availableCoordinate = gameState.availableCandidates()
                .filter({ available in available.coordinate == coordinate })
                .first else {
                throw PreconditionFailure.cannotPlace(at: coordinate, on: gameState)
            }
            return gameState.unsafeNext(by: availableCoordinate).afterState
        }
    }
}



extension GameCommand.PreconditionFailure: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .cannotPass(on: let gameState):
            return "Cannot pass on:\n\(gameState.debugDescription)"
        case .cannotPlace(at: let coordinate, on: let gameState):
            let availableCoordinateString = gameState.availableCandidates()
                .map { $0.debugDescription }
                .joined(separator: ", ")
            return "Cannot place at \(coordinate).\nAvailable coordinates: \(availableCoordinateString)\n\n\(gameState.debugDescription)"
        }
    }
}

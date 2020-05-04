enum GameCommand {
    case pass
    case place(at: Coordinate)



    enum PreconditionFailure: Error, CustomDebugStringConvertible {
        case cannotPass(on: GameState)
        case cannotPlace(at: Coordinate, on: GameState)

        var debugDescription: String {
            switch self {
            case .cannotPass(on: let gameState):
                return "Cannot pass on:\n\(gameState.debugDescription)"
            case .cannotPlace(at: let coordinate, on: let gameState):
                return "Cannot place at \(coordinate) on:\n\(gameState.debugDescription)"
            }
        }
    }



    func unsafeExecute(on gameState: GameState) throws -> GameState {
        switch self {
        case .pass:
            guard gameState.availableCoordinates().isEmpty else {
                throw PreconditionFailure.cannotPass(on: gameState)
            }
            return gameState.unsafePass()

        case .place(at: let coordinate):
            guard let availableCoordinate = gameState.availableCoordinates()
                .filter({ available in available.coordinate == coordinate })
                .first else {
                throw PreconditionFailure.cannotPlace(at: coordinate, on: gameState)
            }
            return gameState.unsafeNext(by: availableCoordinate)
        }
    }
}

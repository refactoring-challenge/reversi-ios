public struct GameAutomatorAvailabilities {
    public let first: GameAutomatorAvailability
    public let second: GameAutomatorAvailability


    public init(first: GameAutomatorAvailability, second: GameAutomatorAvailability) {
        self.first = first
        self.second = second
    }


    public static let bothDisabled = GameAutomatorAvailabilities(first: .disabled, second: .disabled)


    public func availability(on gameState: GameState) -> GameAutomatorAvailability {
        switch gameState.turn {
        case .first:
            return self.first
        case .second:
            return self.second
        }
    }


    public func updated(availability: GameAutomatorAvailability, for turn: Turn) -> GameAutomatorAvailabilities {
        switch turn {
        case .first:
            return .init(first: availability, second: self.second)
        case .second:
            return .init(first: self.first, second: availability)
        }
    }
}



extension GameAutomatorAvailabilities: Equatable {}

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
}



extension GameAutomatorAvailabilities: Equatable {}


extension GameAutomatorAvailabilities: Codable {}

public struct AutomationAvailabilities {
    public let first: AutomationAvailability
    public let second: AutomationAvailability


    public init(first: AutomationAvailability, second: AutomationAvailability) {
        self.first = first
        self.second = second
    }


    public static let bothDisabled = AutomationAvailabilities(first: .disabled, second: .disabled)


    public func availability(on gameState: GameState) -> AutomationAvailability {
        switch gameState.turn {
        case .first:
            return self.first
        case .second:
            return self.second
        }
    }


    public func updated(availability: AutomationAvailability, for turn: Turn) -> AutomationAvailabilities {
        switch turn {
        case .first:
            return .init(first: availability, second: self.second)
        case .second:
            return .init(first: self.first, second: availability)
        }
    }
}



extension AutomationAvailabilities: Equatable {}

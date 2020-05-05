public struct PlayersAutomationAvailability {
    public let first: PlayerAutomationAvailability
    public let second: PlayerAutomationAvailability


    public init(first: PlayerAutomationAvailability, second: PlayerAutomationAvailability) {
        self.first = first
        self.second = second
    }


    public static let initial = PlayersAutomationAvailability(first: .disabled, second: .disabled)


    public func availability(for turn: Turn) -> PlayerAutomationAvailability {
        switch turn {
        case .first:
            return self.first
        case .second:
            return self.second
        }
    }


    public func toggled(for turn: Turn) -> PlayersAutomationAvailability {
        switch turn {
        case .first:
            return .init(first: self.first.toggled, second: self.second)
        case .second:
            return .init(first: self.first, second: self.second.toggled)
        }
    }
}



extension PlayersAutomationAvailability: Equatable {}

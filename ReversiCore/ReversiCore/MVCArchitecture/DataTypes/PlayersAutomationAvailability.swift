struct PlayersAutomationAvailability {
    let first: PlayerAutomationAvailability
    let second: PlayerAutomationAvailability


    static let initial = PlayersAutomationAvailability(first: .disabled, second: .disabled)


    func availability(for turn: Turn) -> PlayerAutomationAvailability {
        switch turn {
        case .first:
            return self.first
        case .second:
            return self.second
        }
    }


    func toggled(for turn: Turn) -> PlayersAutomationAvailability {
        switch turn {
        case .first:
            return .init(first: self.first.toggled, second: self.second)
        case .second:
            return .init(first: self.first, second: self.second.toggled)
        }
    }
}



extension PlayersAutomationAvailability: Equatable {}

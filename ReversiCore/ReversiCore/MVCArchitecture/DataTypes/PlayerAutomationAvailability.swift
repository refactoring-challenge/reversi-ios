enum PlayerAutomationAvailability {
    case enabled
    case disabled


    var toggled: PlayerAutomationAvailability {
        switch self {
        case .enabled:
            return .disabled
        case .disabled:
            return .enabled
        }
    }
}



extension PlayerAutomationAvailability: Equatable {}

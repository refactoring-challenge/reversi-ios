public enum PlayerAutomationAvailability {
    case enabled
    case disabled


    public var toggled: PlayerAutomationAvailability {
        switch self {
        case .enabled:
            return .disabled
        case .disabled:
            return .enabled
        }
    }
}



extension PlayerAutomationAvailability: Equatable {}

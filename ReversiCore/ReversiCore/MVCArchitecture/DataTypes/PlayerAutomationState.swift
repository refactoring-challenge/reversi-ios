enum PlayerAutomationState {
    case enabled
    case disabled


    var toggled: PlayerAutomationState {
        switch self {
        case .enabled:
            return .disabled
        case .disabled:
            return .enabled
        }
    }
}



extension PlayerAutomationState: Equatable {}

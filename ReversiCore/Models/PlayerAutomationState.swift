public enum PlayerAutomationState {
    case enabled
    case disabled


    public var toggled: PlayerAutomationState {
        switch self {
        case .enabled:
            return .disabled
        case .disabled:
            return .enabled
        }
    }
}

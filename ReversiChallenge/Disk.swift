public enum Disk: Equatable {
    case dark
    case light
}

extension Disk {
    public var reversed: Disk {
        switch self {
        case .dark: return .light
        case .light: return .dark
        }
    }
}

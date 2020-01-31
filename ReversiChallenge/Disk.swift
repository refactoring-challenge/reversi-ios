public enum Disk {
    case dark
    case light
}

extension Disk: Hashable {}

extension Disk {
    public var flipped: Disk {
        switch self {
        case .dark: return .light
        case .light: return .dark
        }
    }
    
    public mutating func flip() {
        self = flipped
    }
}

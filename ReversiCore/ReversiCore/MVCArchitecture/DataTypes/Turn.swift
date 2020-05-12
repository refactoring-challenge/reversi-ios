public enum Turn: String, CaseIterable {
    case first
    case second


    public var disk: Disk {
        switch self {
        case .first:
            return .dark
        case .second:
            return .light
        }
    }


    public var next: Turn {
        switch self {
        case .first:
            return .second
        case .second:
            return .first
        }
    }
}



extension Turn: Hashable {}



extension Turn: Codable {}



extension Turn: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .first:
            return "x"
        case .second:
            return "o"
        }
    }
}
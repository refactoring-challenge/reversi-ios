public enum Turn: CaseIterable, Hashable {
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
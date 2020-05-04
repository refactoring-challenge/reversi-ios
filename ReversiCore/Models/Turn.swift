enum Turn: CaseIterable, Hashable {
    case first
    case second


    var disk: Disk {
        switch self {
        case .first:
            return .dark
        case .second:
            return .light
        }
    }


    var next: Turn {
        switch self {
        case .first:
            return .second
        case .second:
            return .first
        }
    }
}
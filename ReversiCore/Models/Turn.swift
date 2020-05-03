enum Turn: Hashable {
    case first
    case next


    var disk: Disk {
        switch self {
        case .first:
            return .dark
        case .next:
            return .light
        }
    }


    var next: Turn {
        switch self {
        case .first:
            return .next
        case .next:
            return .first
        }
    }
}
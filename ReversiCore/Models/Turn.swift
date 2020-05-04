enum Turn: CaseIterable {
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



extension Turn: Hashable {
}



extension Turn: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .first:
            return "x"
        case .second:
            return "o"
        }
    }
}
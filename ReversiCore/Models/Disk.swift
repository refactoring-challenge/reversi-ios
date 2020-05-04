public enum Disk {
    case dark
    case light

    public var flipped: Disk {
        switch self {
        case .dark: return .light
        case .light: return .dark
        }
    }
}



extension Disk: Hashable {
}



extension Disk: CaseIterable {
}



extension Disk: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .dark:
            return "x"
        case .light:
            return "o"
        }
    }
}



extension Optional: CustomStringConvertible where Wrapped == Disk {
    public var description: String {
        guard let disk = self else { return " " }
        return disk.debugDescription
    }
}

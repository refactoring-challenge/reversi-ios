public enum Disk: CaseIterable {
    case dark
    case light


    public static let sides: [Disk] = Disk.allCases


    public var flipped: Disk {
        switch self {
        case .dark: return .light
        case .light: return .dark
        }
    }


    public mutating func flip() {
        self = self.flipped
    }
}



extension Disk: Hashable {}



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

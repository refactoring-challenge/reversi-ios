public enum Disk: String, CaseIterable {
    case dark = "x"
    case light = "o"


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



extension Disk: Codable {}



extension Disk: CustomDebugStringConvertible {
    public var debugDescription: String { self.rawValue }
}



extension Optional: CustomStringConvertible where Wrapped == Disk {
    public var description: String {
        guard let disk = self else { return " " }
        return disk.rawValue
    }
}

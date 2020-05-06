public enum Distance: Int, CaseIterable {
    // BUG9: Removing .one to limit line lengths caused that users of .allCases or .init(rawValue:_) get broken.
    case one = 1
    case two
    case three
    case four
    case five
    case six
    case seven


    public var prev: Distance? {
        Distance(rawValue: self.rawValue - 1)
    }


    public var next: Distance? {
        Distance(rawValue: self.rawValue + 1)
    }


    // NOTE: Distance.allCases are ordered by their declaration, so they are ordered by ascendant.
    // > The synthesized allCases collection provides the cases in order of their declaration.
    // > https://developer.apple.com/documentation/swift/caseiterable
    public static let allCasesByAscendant = Distance.allCases
}



extension Distance: Hashable {}

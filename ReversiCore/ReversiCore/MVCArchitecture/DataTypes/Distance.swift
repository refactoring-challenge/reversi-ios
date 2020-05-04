enum Distance: Int, CaseIterable {
    case one = 1
    case two
    case three
    case four
    case five
    case six
    case seven


    var prev: Distance? {
        Distance(rawValue: self.rawValue - 1)
    }


    var next: Distance? {
        Distance(rawValue: self.rawValue + 1)
    }


    // NOTE: Distance.allCases are ordered by their declaration, so they are ordered by ascendant.
    // > The synthesized allCases collection provides the cases in order of their declaration.
    // > https://developer.apple.com/documentation/swift/caseiterable
    static let allCasesByAscendant = Distance.allCases


    static let AllCasesLongerThan1ByAscendant = Distance.allCasesByAscendant.dropFirst()
}



extension Distance: Hashable {}

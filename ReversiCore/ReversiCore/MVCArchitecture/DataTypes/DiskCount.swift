public struct DiskCount {
    public let first: Int
    public let second: Int


    public init(first: Int, second: Int) {
        self.first = first
        self.second = second
    }


    public func currentGameResult() -> GameResult {
        if self.first == self.second {
            return .draw
        }
        return self.first > self.second
            ? .win(who: .first)
            : .win(who: .second)
    }
}



extension DiskCount: Hashable {}

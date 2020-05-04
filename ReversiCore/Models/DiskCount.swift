public struct DiskCount: Hashable {
    public let light: Int
    public let dark: Int


    public func currentGameResult() -> GameResult {
        if self.dark == self.light {
            return .draw
        }
        return self.dark > self.light
            ? .win(who: .first)
            : .win(who: .second)
    }
}

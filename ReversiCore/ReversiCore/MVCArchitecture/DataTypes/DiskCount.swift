struct DiskCount {
    let light: Int
    let dark: Int


    func currentGameResult() -> GameResult {
        if self.dark == self.light {
            return .draw
        }
        return self.dark > self.light
            ? .win(who: .first)
            : .win(who: .second)
    }
}



extension DiskCount: Hashable {}

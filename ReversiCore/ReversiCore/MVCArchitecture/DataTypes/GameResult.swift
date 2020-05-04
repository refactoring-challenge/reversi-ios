enum GameResult {
    case win(who: Turn)
    case draw
}



extension GameResult: Hashable {}
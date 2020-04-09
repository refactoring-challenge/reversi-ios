import Foundation

struct Turn {
    let side: Disk
    let player: Player
}

enum CurrentTurn {
    case turn(Turn)
    case gameOverWon(Turn)
    case gameOverTied

    var isGameOver: Bool {
        switch self {
        case .gameOverWon, .gameOverTied:
            return true
        case .turn:
            return false
        }
    }
}

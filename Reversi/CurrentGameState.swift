import Foundation

enum CurrentGameState {
    case turn(Disk)
    case gameOverWon(Disk)
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

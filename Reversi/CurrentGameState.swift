import Foundation

enum CurrentGameState {
    case turn(Disk)
    case gameOverWon(Disk)
    case gameOverTied
}

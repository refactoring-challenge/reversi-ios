import Foundation

final class GameState {
    private(set) var turn: Disk? = .dark // `nil` if the current game is over
    var isGameOver: Bool { turn == nil }

    func setTurn(turn: Disk?) {
        self.turn = turn
    }

    func gameOver() {
        turn = nil
    }

    func reset() {
        turn = .dark
    }

    func nextTurn() -> Disk? {
        guard var turn = turn else { return nil }
        turn.flip()
        self.turn = turn
        return turn
    }
}

final class PlayersState {
    private var player1: Player = .manual
    private var player2: Player = .manual

    func setPlayer(player: Player, at side: Disk) {
        switch side {
        case .dark: player1 = player
        case .light: player2 = player
        }
    }

    func player(at side: Disk) -> Player {
        switch side {
        case .dark: return player1
        case .light: return player2
        }
    }

    func reset() {
        player1 = .manual
        player2 = .manual
    }
}

final class ReversiState {
    let boardState: BoardState = .init()
    var constant: BoardState.Constant { boardState.constant }
    private let gameState: GameState = .init()
    private let playersState: PlayersState = .init()
    private let persistentInteractor: PersistentInteractor

    init(persistentInteractor: PersistentInteractor = PersistentInteractorImpl()) {
        self.persistentInteractor = persistentInteractor
    }

    var currentTurn: Disk? {
        gameState.turn
    }

    /* Players */
    var currentPlayer: Player {
        guard let turn = gameState.turn else { preconditionFailure() }
        return playersState.player(at: turn)
    }

    func player(at side: Disk) -> Player {
        playersState.player(at: side)
    }

    func setPlayer(player: Player, at side: Disk) {
        playersState.setPlayer(player: player, at: side)
    }

    /* Reversi logics */
    func validMoves(for side: Disk) -> [(x: Int, y: Int)] {
        boardState.validMoves(for: side)
    }

    func flippedDiskCoordinatesByPlacingDisk(_ disk: Disk, atX x: Int, y: Int) -> [(Int, Int)] {
        boardState.flippedDiskCoordinatesByPlacingDisk(disk, atX: x, y: y)
    }

    /* Game life cycle */
    func newGame() throws {
        resetAllState()
        try? saveGame()
    }

    func nextTurn() -> Disk? {
        gameState.nextTurn()
    }

    func gameover() {
        gameState.gameOver()
    }

    func canPlayTurnOfComputer(at side: Disk) -> Bool {
        if side == gameState.turn, case .computer = playersState.player(at: side) {
            return true
        } else {
            return false
        }
    }

    /* Save and Load */
    func saveGame() throws {
        try persistentInteractor.saveGame(turn: gameState.turn, playersState: playersState, boardState: boardState)
    }

    func loadGame() throws {
        resetAllState()

        let loadData = try persistentInteractor.loadGame(constant: constant)
        gameState.setTurn(turn: loadData.turn)
        loadData.players.enumerated().forEach {
            playersState.setPlayer(player: $0.element, at: Disk(index: $0.offset))
        }
        loadData.squares.forEach {
            boardState.setDisk($0.disk, atX: $0.x, y: $0.y)
        }
    }

    private func resetAllState() {
        gameState.reset()
        boardState.reset()
        playersState.reset()
    }
}

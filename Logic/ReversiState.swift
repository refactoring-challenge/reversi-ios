import Foundation

final class SideState {
    private(set) var side: Disk? = .dark // `nil` if the current game is over

    func setSide(_ side: Disk?) {
        self.side = side
    }

    func gameOver() {
        side = nil
    }

    func reset() {
        side = .dark
    }

    func nextSide() -> Disk? {
        guard let temp = side else { return nil }
        self.side = temp.flipped
        return self.side
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

public final class ReversiState {
    private let boardState: BoardState = .init()
    private let sideState: SideState = .init()
    private let playersState: PlayersState = .init()
    private let persistentInteractor: PersistentInteractor

    public init() {
        self.persistentInteractor = PersistentInteractorImpl()
    }

    init(persistentInteractor: PersistentInteractor = PersistentInteractorImpl()) {
        self.persistentInteractor = persistentInteractor
    }

    public var currentTurn: CurrentTurn {
        if let side = sideState.side {
            let player = playersState.player(at: side)
            return CurrentTurn.turn(Turn(side: side, player: player))
        } else {
            if let winner = boardState.sideWithMoreDisks() {
                let player = playersState.player(at: winner)
                return CurrentTurn.gameOverWon(Turn(side: winner, player: player))
            } else {
                return CurrentTurn.gameOverTied
            }
        }
    }

    /* Player */
    public func changePlayer(side: Disk, player: Player) {
        playersState.setPlayer(player: player, at: side)
    }

    public func player(at side: Disk) -> Player {
        playersState.player(at: side)
    }

    /* Disk */
    public func diskAt(x: Int, y: Int) -> Disk? {
        boardState.diskAt(x: x, y: y)
    }

    public func setDisk(_ disk: Disk?, atX x: Int, y: Int) {
        boardState.setDisk(disk, atX: x, y: y)
    }

    public func count(of disk: Disk) -> Int {
        boardState.count(of: disk)
    }

    /* Reversi logics */
    public func validMoves(for turn: Turn) -> [(x: Int, y: Int)] {
        boardState.validMoves(for: turn.side)
    }

    public struct DiskPlacementError: Error {
        public let disk: Disk
        public let x: Int
        public let y: Int
    }

    public func flippedDiskCoordinatesByPlacingDisk(_ disk: Disk, atX x: Int, y: Int) throws -> [(Int, Int)] /* DiskPlacementError */ {
        let diskCoordinates = boardState.flippedDiskCoordinatesByPlacingDisk(disk, atX: x, y: y)
        if diskCoordinates.isEmpty {
            throw DiskPlacementError(disk: disk, x: x, y: y)
        }
        return diskCoordinates
    }

    /* Game life cycle */
    public func newGame() throws {
        resetAllState()
        try? saveGame()
    }

    public func nextTurn() -> Turn? {
        guard let side = sideState.nextSide() else { return nil }
        let player = playersState.player(at: side)
        return Turn(side: side, player: player)
    }

    public func flippedTurn(_ turn: Turn) -> Turn {
        let side = turn.side.flipped
        let player = playersState.player(at: side)
        return Turn(side: side, player: player)
    }

    public func gameover() {
        sideState.gameOver()
    }

    public func canPlayTurnOfComputer(at side: Disk) -> Bool {
        if side == sideState.side, case .computer = playersState.player(at: side) {
            return true
        } else {
            return false
        }
    }

    /* Save and Load */
    public func saveGame() throws {
        try persistentInteractor.saveGame(side: sideState.side, playersState: playersState, boardState: boardState)
    }

    public func loadGame() throws {
        resetAllState()

        let loadData = try persistentInteractor.loadGame()
        sideState.setSide(loadData.side)
        loadData.players.enumerated().forEach {
            playersState.setPlayer(player: $0.element, at: Disk(index: $0.offset))
        }
        loadData.squares.forEach {
            boardState.setDisk($0.disk, atX: $0.x, y: $0.y)
        }
        checkGameOver()
    }

    private func checkGameOver() {
        guard let currentSide = sideState.side else { return } // Already game over
        if boardState.validMoves(for: currentSide).isEmpty && boardState.validMoves(for: currentSide.flipped).isEmpty {
            sideState.gameOver()
        }
    }

    private func resetAllState() {
        sideState.reset()
        boardState.reset()
        playersState.reset()
    }
}

extension Disk {
    fileprivate var flipped: Disk {
        switch self {
        case .dark: return .light
        case .light: return .dark
        }
    }
}

import Foundation

enum Player: Int {
    case manual = 0
    case computer = 1
}

class PlayersState {
    private var player1: Player = .manual
    private var player2: Player = .manual

    func setPlayer(player: Player, at index: Int) {
        switch index {
        case 0: player1 = player
        case 1: player2 = player
        default: preconditionFailure()
        }
    }

    func player(at index: Int) -> Player {
        switch index {
        case 0: return player1
        case 1: return player2
        default: preconditionFailure()
        }
    }

    func reset() {
        player1 = .manual
        player2 = .manual
    }
}

class ReversiState {
    let boardState: BoardState = .init()
    var constant: BoardState.Constant { boardState.constant }
    private let playersState: PlayersState = .init()
    private let persistentInteractor: PersistentInteractor

    init(persistentInteractor: PersistentInteractor = PersistentInteractorImpl()) {
        self.persistentInteractor = persistentInteractor
    }

    /* Players */
    var playerThisTurn: Player {
        guard let turn = turn else { preconditionFailure() }
        return playersState.player(at: turn.index)
    }

    func player(at index: Int) -> Player {
        playersState.player(at: index)
    }

    func setPlayer(player: Player, at index: Int) {
        playersState.setPlayer(player: player, at: index)
    }

    /* Reversi logics */
    private(set) var turn: Disk? = .dark // `nil` if the current game is over

    func canPlaceDisk(_ disk: Disk, atX x: Int, y: Int) -> Bool {
        !flippedDiskCoordinatesByPlacingDisk(disk, atX: x, y: y).isEmpty
    }

    func validMoves(for side: Disk) -> [(x: Int, y: Int)] {
        var coordinates: [(Int, Int)] = []
        for y in constant.yRange {
            for x in constant.xRange {
                if canPlaceDisk(side, atX: x, y: y) {
                    coordinates.append((x, y))
                }
            }
        }
        return coordinates
    }

    func flippedDiskCoordinatesByPlacingDisk(_ disk: Disk, atX x: Int, y: Int) -> [(Int, Int)] {
        let directions = [
            (x: -1, y: -1),
            (x:  0, y: -1),
            (x:  1, y: -1),
            (x:  1, y:  0),
            (x:  1, y:  1),
            (x:  0, y:  1),
            (x: -1, y:  0),
            (x: -1, y:  1),
        ]

        guard boardState.diskAt(x: x, y: y) == nil else {
            return []
        }

        var diskCoordinates: [(Int, Int)] = []

        for direction in directions {
            var x = x
            var y = y

            var diskCoordinatesInLine: [(Int, Int)] = []
            flipping: while true {
                x += direction.x
                y += direction.y

                switch (disk, boardState.diskAt(x: x, y: y)) { // Uses tuples to make patterns exhaustive
                case (.dark, .some(.dark)), (.light, .some(.light)):
                    diskCoordinates.append(contentsOf: diskCoordinatesInLine)
                    break flipping
                case (.dark, .some(.light)), (.light, .some(.dark)):
                    diskCoordinatesInLine.append((x, y))
                case (_, .none):
                    break flipping
                }
            }
        }

        return diskCoordinates
    }

    /* Game life cycle */
    var isGameOver: Bool {
        turn == nil
    }

    func newGame() throws {
        boardState.reset()
        playersState.reset()
        turn = .dark
        try? saveGame()
    }

    func nextTurn() -> Disk? {
        guard var turn = turn else { return nil }
        turn.flip()
        self.turn = turn
        return turn
    }

    func gameover() {
        turn = nil
    }

    func canPlayTurnOfComputer(at side: Disk) -> Bool {
        if side == turn, case .computer = playersState.player(at: side.index) {
            return true
        } else {
            return false
        }
    }

    /* Save and Load */
    func saveGame() throws {
        try persistentInteractor.saveGame(turn: turn, playersState: playersState, boardState: boardState)
    }

    func loadGame() throws {
        boardState.reset()
        playersState.reset()

        let loadData = try persistentInteractor.loadGame(constant: constant)
        turn = loadData.turn
        loadData.players.enumerated().forEach {
            playersState.setPlayer(player: $0.element, at: $0.offset)
        }
        loadData.squares.forEach {
            boardState.setDisk($0.disk, atX: $0.x, y: $0.y)
        }
    }
}

extension Disk {
    init(index: Int) {
        for side in Disk.sides {
            if index == side.index {
                self = side
                return
            }
        }
        preconditionFailure("Illegal index: \(index)")
    }

    var index: Int {
        switch self {
        case .dark: return 0
        case .light: return 1
        }
    }
}

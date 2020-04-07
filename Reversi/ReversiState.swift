import Foundation

class ReversiState {
    enum Player: Int {
        case manual = 0
        case computer = 1
    }

    var boardState: BoardState = .init()

    /* Player */
    var player1: Player = .manual
    var player2: Player = .manual

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
    var playerThisTurn: Player {
        guard let turn = turn else { preconditionFailure() }
        return player(at: turn.index)
    }

    var turn: Disk? = .dark // `nil` if the current game is over

    /* Game life cycle */
    var isGameOver: Bool {
        turn == nil
    }

    func newGame() {
        turn = .dark
        player1 = .manual
        player2 = .manual
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
        if side == turn, case .computer = player(at: side.index) {
            return true
        } else {
            return false
        }
    }

    /* Save and Load */
    enum FileIOError: Error {
        case write(path: String, cause: Error?)
        case read(path: String, cause: Error?)
    }

    private var path: String {
        (NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first! as NSString).appendingPathComponent("Game")
    }

    func saveGame() throws {
        var output: String = ""
        output += turn.symbol

        for side in Disk.sides {
            output += player(at: side.index).rawValue.description
        }
        output += "\n"

        for y in boardState.yRange {
            for x in boardState.xRange {
                output += boardState.diskAt(x: x, y: y).symbol
            }
            output += "\n"
        }

        do {
            try output.write(toFile: path, atomically: true, encoding: .utf8)
        } catch let error {
            throw FileIOError.read(path: path, cause: error)
        }
    }

    func loadGame() throws -> [(disk: Disk?, x: Int, y: Int)] {
        let input = try String(contentsOfFile: path, encoding: .utf8)
        var lines: ArraySlice<Substring> = input.split(separator: "\n")[...]

        guard var line = lines.popFirst() else {
            throw FileIOError.read(path: path, cause: nil)
        }

        do { // turn
            guard
                let diskSymbol = line.popFirst(),
                let disk = Optional<Disk>(symbol: diskSymbol.description)
            else {
                throw FileIOError.read(path: path, cause: nil)
            }
            turn = disk
        }

        // players
        for side in Disk.sides {
            guard
                let playerSymbol = line.popFirst(),
                let playerNumber = Int(playerSymbol.description),
                let player = Player(rawValue: playerNumber)
            else {
                throw FileIOError.read(path: path, cause: nil)
            }
            setPlayer(player: player, at: side.index)
        }

        var results: [(disk: Disk?, x: Int, y: Int)] = []
        do { // board
            guard lines.count == boardState.height else {
                throw FileIOError.read(path: path, cause: nil)
            }

            var y = 0
            while let line = lines.popFirst() {
                var x = 0
                for character in line {
                    let disk = Disk?(symbol: "\(character)").flatMap { $0 }
                    results.append((disk: disk, x: x, y: y))
                    x += 1
                }
                guard x == boardState.width else {
                    throw FileIOError.read(path: path, cause: nil)
                }
                y += 1
            }
            guard y == boardState.height else {
                throw FileIOError.read(path: path, cause: nil)
            }
        }
        return results
    }
}

extension Optional where Wrapped == Disk {
    init?<S: StringProtocol>(symbol: S) {
        switch symbol {
        case "x":
            self = .some(.dark)
        case "o":
            self = .some(.light)
        case "-":
            self = .none
        default:
            return nil
        }
    }

    var symbol: String {
        switch self {
        case .some(.dark):
            return "x"
        case .some(.light):
            return "o"
        case .none:
            return "-"
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


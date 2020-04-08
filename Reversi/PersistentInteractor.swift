import Foundation

struct LoadData {
    let turn: Disk?
    let players: [Player]
    let squares: [(disk: Disk?, x: Int, y: Int)]
}

protocol PersistentInteractor {
    func saveGame(turn: Disk?, playersState: PlayersState, boardState: BoardState) throws /* FileIOError */
    func loadGame(constant: BoardState.Constant) throws -> LoadData /* FileIOError */
}

private let defaultPath = (NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first! as NSString).appendingPathComponent("Game")

class PersistentInteractorImpl: PersistentInteractor {
    enum PersistentError: Error {
        case parse(path: String, cause: Error?)
    }

    private let repository: Repository
    private let path: String

    init(path: String = defaultPath, repository: Repository = RepositoryImpl()) {
        self.path = path
        self.repository = repository
    }

    func saveGame(turn: Disk?, playersState: PlayersState, boardState: BoardState) throws {
        let data = createSaveData(turn: turn, playersState: playersState, boardState: boardState)
        try repository.saveData(path: path, data: data)
    }

    func loadGame(constant: BoardState.Constant) throws -> LoadData {
        let lines: ArraySlice<Substring> = try repository.loadData(path: path)
        return try parseLoadData(lines: lines, constant: constant)
    }

    func createSaveData(turn: Disk?, playersState: PlayersState, boardState: BoardState) -> String {
        let constant = boardState.constant
        var output: String = ""
        output += turn.symbol

        for side in Disk.sides {
            output += playersState.player(at: side).rawValue.description
        }
        output += "\n"

        for y in constant.yRange {
            for x in constant.xRange {
                output += boardState.diskAt(x: x, y: y).symbol
            }
            output += "\n"
        }
        return output
    }

    func parseLoadData(lines: ArraySlice<Substring>, constant: BoardState.Constant) throws -> LoadData {
        var lines = lines

        guard var line = lines.popFirst() else {
            throw PersistentError.parse(path: path, cause: nil)
        }

        // turn
        let turn: Disk?
        do {
            guard
                let diskSymbol = line.popFirst(),
                let disk = Optional<Disk>(symbol: diskSymbol.description)
            else {
                throw PersistentError.parse(path: path, cause: nil)
            }
            turn = disk
        }

        // players
        let players: [Player] = try Disk.sides.map { _ in
            guard
                let playerSymbol = line.popFirst(),
                let playerNumber = Int(playerSymbol.description),
                let player = Player(rawValue: playerNumber)
            else {
                throw PersistentError.parse(path: path, cause: nil)
            }
            return player
        }

        // board
        var squares: [(disk: Disk?, x: Int, y: Int)] = []
        do {
            guard lines.count == constant.height else {
                throw PersistentError.parse(path: path, cause: nil)
            }

            var y = 0
            while let line = lines.popFirst() {
                var x = 0
                for character in line {
                    let disk = Disk?(symbol: "\(character)").flatMap { $0 }
                    squares.append((disk: disk, x: x, y: y))
                    x += 1
                }
                guard x == constant.width else {
                    throw PersistentError.parse(path: path, cause: nil)
                }
                y += 1
            }
            guard y == constant.height else {
                throw PersistentError.parse(path: path, cause: nil)
            }
        }

        return LoadData(turn: turn, players: players, squares: squares)
    }
}


extension Optional where Wrapped == Disk {
    fileprivate init?<S: StringProtocol>(symbol: S) {
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

    fileprivate var symbol: String {
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

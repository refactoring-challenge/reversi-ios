import Foundation

struct LoadData {
    let side: Disk?
    let players: [Player]
    let squares: [(disk: Disk?, x: Int, y: Int)]
}

protocol PersistentInteractor {
    func saveGame(side: Disk?, playersState: PlayersState, boardState: BoardState) throws /* FileIOError */
    func loadGame() throws -> LoadData /* FileIOError, PersistentError */
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

    func saveGame(side: Disk?, playersState: PlayersState, boardState: BoardState) throws {
        let data = createSaveData(side: side, playersState: playersState, boardState: boardState)
        try repository.saveData(path: path, data: data)
    }

    func loadGame() throws -> LoadData {
        let lines: ArraySlice<Substring> = try repository.loadData(path: path)
        return try parseLoadData(lines: lines)
    }

    func createSaveData(side: Disk?, playersState: PlayersState, boardState: BoardState) -> String {
        var output: String = ""
        output += side.symbol

        for side in Disk.sides {
            output += playersState.player(at: side).rawValue.description
        }
        output += "\n"

        for y in BoardConstant.yRange {
            for x in BoardConstant.xRange {
                output += boardState.diskAt(x: x, y: y).symbol
            }
            output += "\n"
        }
        return output
    }

    func parseLoadData(lines: ArraySlice<Substring>) throws -> LoadData {
        var lines = lines

        guard var line = lines.popFirst() else {
            throw PersistentError.parse(path: path, cause: nil)
        }

        // side
        let side: Disk?
        do {
            guard
                let diskSymbol = line.popFirst(),
                let disk = Optional<Disk>(symbol: diskSymbol.description)
            else {
                throw PersistentError.parse(path: path, cause: nil)
            }
            side = disk
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
            guard lines.count == BoardConstant.height else {
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
                guard x == BoardConstant.width else {
                    throw PersistentError.parse(path: path, cause: nil)
                }
                y += 1
            }
            guard y == BoardConstant.height else {
                throw PersistentError.parse(path: path, cause: nil)
            }
        }

        return LoadData(side: side, players: players, squares: squares)
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

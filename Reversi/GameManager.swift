import Foundation
import Combine

class GameManager {
    let onStateChanged = PassthroughSubject<Void, Never>()
    let onPlayerPass = PassthroughSubject<Void, Never>()
    let onStartThinking = PassthroughSubject<Disk, Never>()
    let onFinishThinking = PassthroughSubject<Disk, Never>()
    let onMakeMove = PassthroughSubject<Move, Never>()

    var gameState: GameState {
        if let turn = turn {
            return .playing(side: turn)
        } else {
            if let winner = sideWithMoreDisks() {
                return .finished(winner: winner)
            } else {
                return .finished(winner: nil)
            }
        }
    }
    var boardView: BoardView
    
    /// どちらの色のプレイヤーのターンかを表します。ゲーム終了時は `nil` です。
    private var turn: Disk? = .dark
    private var players: [Player] = [.manual, .manual]
    private var playerCancellers: [Disk: Canceller] = [:]

    init(boardView: BoardView) {
        self.boardView = boardView
    }

    private var path: URL { FileManager().urls(for: .libraryDirectory, in: .userDomainMask)[0].appendingPathComponent("Game") }

    /// ゲームの状態を初期化し、新しいゲームを開始します。
    func newGame() {
        for side in Disk.sides {
            playerCancellers[side]?.cancel()
            playerCancellers.removeValue(forKey: side)
        }

        boardView.reset()
        turn = .dark
        players = [.manual, .manual]

        onStateChanged.send()

        try? saveGame()
    }

    /// ゲームの状態をファイルに書き出し、保存します。
    func saveGame() throws {
        var output: String = ""
        output += turn.symbol
        for side in Disk.sides {
            output += players[side.index].rawValue.description
        }
        output += "\n"

        for y in boardView.yRange {
            for x in boardView.xRange {
                output += boardView.diskAt(x: x, y: y).symbol
            }
            output += "\n"
        }

        do {
            try output.write(to: path, atomically: true, encoding: .utf8)
        } catch let error {
            throw FileIOError.read(path: path, cause: error)
        }
    }

    /// ゲームの状態をファイルから読み込み、復元します。
    func loadGame() throws {
        let input = try String(contentsOf: path, encoding: .utf8)
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
            players[side.index] = player
        }

        do { // board
            guard lines.count == boardView.height else {
                throw FileIOError.read(path: path, cause: nil)
            }

            var y = 0
            while let line = lines.popFirst() {
                var x = 0
                for character in line {
                    let disk = Disk?(symbol: "\(character)").flatMap { $0 }
                    boardView.setDisk(disk, atX: x, y: y, animated: false)
                    x += 1
                }
                guard x == boardView.width else {
                    throw FileIOError.read(path: path, cause: nil)
                }
                y += 1
            }
            guard y == boardView.height else {
                throw FileIOError.read(path: path, cause: nil)
            }
        }

        onStateChanged.send()
    }

    func changePlayerMode(for side: Disk, mode: Int) {
        if let canceller = playerCancellers[side] {
            canceller.cancel()
        }

        if side == turn, case .computer = Player(rawValue: mode)! {
            playTurnOfComputer(completion: {})
        }
    }
    
    /// プレイヤーの行動を待ちます。
    func waitForPlayer() {
        guard let turn = turn else { return }
        switch players[turn.index] {
        case .manual:
            break
        case .computer:
            onStartThinking.send(turn)
            playTurnOfComputer { [weak self] in
                guard let self = self else { return }
                self.onFinishThinking.send(turn)
            }
        }
    }

    /// プレイヤーの行動後、そのプレイヤーのターンを終了して次のターンを開始します。
    /// もし、次のプレイヤーに有効な手が存在しない場合、パスとなります。
    /// 両プレイヤーに有効な手がない場合、ゲームの勝敗を表示します。
    func nextTurn() {
        guard var turn = turn else { return }

        turn.flip()

        if validMoves(for: turn).isEmpty {
            if validMoves(for: turn.flipped).isEmpty {
                self.turn = nil
            } else {
                self.turn = turn
                onPlayerPass.send()
            }
        } else {
            self.turn = turn
            waitForPlayer()
        }

        onStateChanged.send()
    }

    func placeDisk(atX x: Int, y: Int) throws {
        guard let turn = turn else { return }
        guard players[turn.index] == .manual else { return }
        try placeDisk(turn, atX: x, y: y)
        nextTurn()
    }

    /// `x`, `y` で指定されたセルに `disk` を置きます。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    /// - Parameter isAnimated: ディスクを置いたりひっくり返したりするアニメーションを表示するかどうかを指定します。
    /// - Parameter completion: アニメーション完了時に実行されるクロージャです。
    ///     このクロージャは値を返さず、アニメーションが完了したかを示す真偽値を受け取ります。
    ///     もし `animated` が `false` の場合、このクロージャは次の run loop サイクルの初めに実行されます。
    /// - Throws: もし `disk` を `x`, `y` で指定されるセルに置けない場合、 `DiskPlacementError` を `throw` します。
    private func placeDisk(_ disk: Disk, atX x: Int, y: Int) throws {
        let diskCoordinates = flippedDiskCoordinatesByPlacingDisk(disk, atX: x, y: y)
        if diskCoordinates.isEmpty {
            throw DiskPlacementError(disk: disk, x: x, y: y)
        }

        let coordinates = [(x, y)] + diskCoordinates
        onMakeMove.send(Move(coordinates: coordinates, disk: disk))
    }

    /// "Computer" が選択されている場合のプレイヤーの行動を決定します。
    private func playTurnOfComputer(completion: @escaping () -> Void) {
        guard let turn = turn else { preconditionFailure() }
        let (x, y) = validMoves(for: turn).randomElement()!

        let cleanUp: () -> Void = { [weak self] in
            guard let self = self else { return }
            self.playerCancellers[turn] = nil
        }
        let canceller = Canceller(cleanUp)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            if canceller.isCancelled { return }
            cleanUp()

            try! self.placeDisk(turn, atX: x, y: y)
            self.nextTurn()
            completion()
        }

        playerCancellers[turn] = canceller
    }

    private func flippedDiskCoordinatesByPlacingDisk(_ disk: Disk, atX x: Int, y: Int) -> [(Int, Int)] {
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

        guard boardView.diskAt(x: x, y: y) == nil else {
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

                switch (disk, boardView.diskAt(x: x, y: y)) { // Uses tuples to make patterns exhaustive
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

    /// `x`, `y` で指定されたセルに、 `disk` が置けるかを調べます。
    /// ディスクを置くためには、少なくとも 1 枚のディスクをひっくり返せる必要があります。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    /// - Returns: 指定されたセルに `disk` を置ける場合は `true` を、置けない場合は `false` を返します。
    func canPlaceDisk(_ disk: Disk, atX x: Int, y: Int) -> Bool {
        !flippedDiskCoordinatesByPlacingDisk(disk, atX: x, y: y).isEmpty
    }

    /// `side` で指定された色のディスクを置ける盤上のセルの座標をすべて返します。
    /// - Returns: `side` で指定された色のディスクを置ける盤上のすべてのセルの座標の配列です。
    func validMoves(for side: Disk) -> [(x: Int, y: Int)] {
        var coordinates: [(Int, Int)] = []

        for y in boardView.yRange {
            for x in boardView.xRange {
                if canPlaceDisk(side, atX: x, y: y) {
                    coordinates.append((x, y))
                }
            }
        }

        return coordinates
    }

    /// `side` で指定された色のディスクが盤上に置かれている枚数を返します。
    /// - Parameter side: 数えるディスクの色です。
    /// - Returns: `side` で指定された色のディスクの、盤上の枚数です。
    func countDisks(of side: Disk) -> Int {
        var count = 0

        for y in boardView.yRange {
            for x in boardView.xRange {
                if boardView.diskAt(x: x, y: y) == side {
                    count +=  1
                }
            }
        }

        return count
    }

    /// 盤上に置かれたディスクの枚数が多い方の色を返します。
    /// 引き分けの場合は `nil` が返されます。
    /// - Returns: 盤上に置かれたディスクの枚数が多い方の色です。引き分けの場合は `nil` を返します。
    func sideWithMoreDisks() -> Disk? {
        let darkCount = countDisks(of: .dark)
        let lightCount = countDisks(of: .light)
        if darkCount == lightCount {
            return nil
        } else {
            return darkCount > lightCount ? .dark : .light
        }
    }

    enum Player: Int {
        case manual = 0
        case computer = 1
    }

    struct Move {
        let coordinates: [(Int, Int)]
        let disk: Disk
    }

    enum FileIOError: Error {
        case write(path: URL, cause: Error?)
        case read(path: URL, cause: Error?)
    }
}

enum GameState {
    case playing(side: Disk)
    case finished(winner: Disk?)
}

private struct DiskPlacementError: Error {
    let disk: Disk
    let x: Int
    let y: Int
}

private extension Optional where Wrapped == Disk {
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

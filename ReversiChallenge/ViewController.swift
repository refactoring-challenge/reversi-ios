import UIKit

class ViewController: UIViewController {
    @IBOutlet private var boardView: BoardView!
    
    @IBOutlet private var messageDiskView: DiskView!
    @IBOutlet private var messageLabel: UILabel!
    @IBOutlet private var messageDiskSizeConstraint: NSLayoutConstraint!
    private var messageDiskSize: CGFloat! // to store the size designated in the storyboard
    
    @IBOutlet private var darkPlayerControl: UISegmentedControl!
    @IBOutlet private var darkCountLabel: UILabel!
    @IBOutlet private var darkPlayerActivityIndicator: UIActivityIndicatorView!

    @IBOutlet private var lightPlayerControl: UISegmentedControl!
    @IBOutlet private var lightCountLabel: UILabel!
    @IBOutlet private var lightPlayerActivityIndicator: UIActivityIndicatorView!
    
    private var turn: Disk? = .dark // `nil` if the current game is over
    
    private var animationCanceller: Canceller?
    private var isAnimating: Bool { animationCanceller != nil }
    
    private var darkPlayerCanceller: Canceller?
    private var lightPlayerCanceller: Canceller?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        boardView.delegate = self
        messageDiskSize = messageDiskSizeConstraint.constant
        
        do {
            try load()
        } catch _ {
            newGame()
        }
    }
}

// MARK: Reversi logics

extension ViewController {
    func count(of disk: Disk) -> Int {
        var count = 0
        
        for y in boardView.yRange {
            for x in boardView.xRange {
                if boardView.diskAt(x: x, y: y) == disk {
                    count +=  1
                }
            }
        }
        
        return count
    }
    
    func sideWithMoreDisks() -> Disk? {
        let darkCount = count(of: .dark)
        let lightCount = count(of: .light)
        if darkCount == lightCount {
            return nil
        } else {
            return darkCount > lightCount ? .dark : .light
        }
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
    
    func canPlaceDisk(_ disk: Disk, atX x: Int, y: Int) -> Bool {
        !flippedDiskCoordinatesByPlacingDisk(disk, atX: x, y: y).isEmpty
    }
    
    func coordinatesToPlaceDisk(_ disk: Disk) -> [(x: Int, y: Int)] {
        var coordinates: [(Int, Int)] = []
        
        for y in boardView.yRange {
            for x in boardView.xRange {
                if canPlaceDisk(disk, atX: x, y: y) {
                    coordinates.append((x, y))
                }
            }
        }
        
        return coordinates
    }

    /// - Parameter completion: A closure to be executed when the animation sequence ends.
    ///     This closure has no return value and takes a single Boolean argument that indicates
    ///     whether or not the animations actually finished before the completion handler was called.
    ///     If `animated` is `false`,  this closure is performed at the beginning of the next run loop cycle. This parameter may be `nil`.
    /// - Throws: `DiskPlacementError` if the `disk` cannot be placed at (`x`, `y`).
    func placeDisk(_ disk: Disk, atX x: Int, y: Int, animated isAnimated: Bool, completion: ((Bool) -> Void)? = nil) throws {
        let diskCoordinates = flippedDiskCoordinatesByPlacingDisk(disk, atX: x, y: y)
        if diskCoordinates.isEmpty {
            throw DiskPlacementError(disk: disk, x: x, y: y)
        }
        
        if isAnimated {
            let cleanUp: () -> Void = { [weak self] in
                self?.animationCanceller = nil
            }
            animationCanceller = Canceller(cleanUp)
            animateSettingDisks(at: [(x, y)] + diskCoordinates, to: disk) { [weak self] finished in
                guard let self = self else { return }
                guard let canceller = self.animationCanceller else { return }
                if canceller.isCancelled { return }
                cleanUp()

                completion?(finished)
                try? self.save()
                self.updateCountLabels()
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.boardView.setDisk(disk, atX: x, y: y, animated: false)
                for (x, y) in diskCoordinates {
                    self.boardView.setDisk(disk, atX: x, y: y, animated: false)
                }
                completion?(true)
                try? self.save()
                self.updateCountLabels()
            }
        }
    }
    
    private func animateSettingDisks<C: Collection>(at coordinates: C, to disk: Disk, completion: @escaping (Bool) -> Void)
        where C.Element == (Int, Int)
    {
        guard let (x, y) = coordinates.first else {
            completion(true)
            return
        }
        
        let animationCanceller = self.animationCanceller!
        boardView.setDisk(disk, atX: x, y: y, animated: true) { [weak self] finished in
            guard let self = self else { return }
            if animationCanceller.isCancelled { return }
            if finished {
                self.animateSettingDisks(at: coordinates.dropFirst(), to: disk, completion: completion)
            } else {
                for (x, y) in coordinates {
                    self.boardView.setDisk(disk, atX: x, y: y, animated: false)
                }
                completion(false)
            }
        }
    }
}

// MARK: Game management

extension ViewController {
    func newGame(_ initializer: ((inout /*turn:*/ Disk?, BoardView) -> ())? = nil) {
        animationCanceller?.cancel()
        animationCanceller = nil
        
        darkPlayerCanceller?.cancel()
        darkPlayerCanceller = nil
        
        lightPlayerCanceller?.cancel()
        lightPlayerCanceller = nil
        
        darkPlayerControl.selectedSegmentIndex = 0
        lightPlayerControl.selectedSegmentIndex = 0
        
        if let resetBoardView = initializer {
            resetBoardView(&turn, boardView)
        } else {
            boardView.reset()
            turn = .dark
        }
        
        updateMessageViews()
        updateCountLabels()
        
        try? save()

        if case .computer = Player(rawValue: darkPlayerControl.selectedSegmentIndex)! {
            playTurnOfComputer()
        }
    }
    
    func nextTurn() {
        guard var turn = self.turn else { return }

        turn.flip()
        
        if coordinatesToPlaceDisk(turn).isEmpty {
            if coordinatesToPlaceDisk(turn.flipped).isEmpty {
                self.turn = nil
                updateMessageViews()
            } else {
                self.turn = turn
                updateMessageViews()
                
                let alertController = UIAlertController(
                    title: "Pass",
                    message: "Cannot place a disk.",
                    preferredStyle: .alert
                )
                alertController.addAction(UIAlertAction(title: "Dismiss", style: .default) { [weak self] _ in
                    self?.nextTurn()
                })
                present(alertController, animated: true)
            }
        } else {
            self.turn = turn
            updateMessageViews()
            
            let playerControl: UISegmentedControl
            switch turn {
            case .dark:
                playerControl = darkPlayerControl
            case .light:
                playerControl = lightPlayerControl
            }
            
            switch Player(rawValue: playerControl.selectedSegmentIndex)! {
            case .manual:
                break
            case .computer:
                playTurnOfComputer()
            }
        }
    }
    
    func playTurnOfComputer() {
        guard let turn = self.turn else { preconditionFailure() }
        let (x, y) = coordinatesToPlaceDisk(turn).randomElement()!
        
        weak var playerActivityIndicator: UIActivityIndicatorView?
        switch turn {
        case .dark:
            playerActivityIndicator = darkPlayerActivityIndicator
        case .light:
            playerActivityIndicator = lightPlayerActivityIndicator
        }
        playerActivityIndicator?.startAnimating()
        
        let cleanUp: () -> Void = { [weak self] in
            guard let self = self else { return }
            playerActivityIndicator?.stopAnimating()
            switch turn {
            case .dark:
                self.darkPlayerCanceller = nil
            case .light:
                self.lightPlayerCanceller = nil
            }
        }
        let canceller = Canceller(cleanUp)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            if canceller.isCancelled { return }
            cleanUp()
            
            try! self.placeDisk(turn, atX: x, y: y, animated: true) { [weak self] _ in
                self?.nextTurn()
            }
        }
        
        switch turn {
        case .dark:
            darkPlayerCanceller = canceller
        case .light:
            lightPlayerCanceller = canceller
        }
    }
}

// MARK: Views

extension ViewController {
    func updateCountLabels() {
        darkCountLabel.text = "\(count(of: .dark))"
        lightCountLabel.text = "\(count(of: .light))"
    }
    
    func updateMessageViews() {
        switch turn {
        case .some(let side):
            messageDiskSizeConstraint.constant = messageDiskSize
            messageDiskView.disk = side
            messageLabel.text = "'s turn"
        case .none:
            if let winner = self.sideWithMoreDisks() {
                messageDiskSizeConstraint.constant = messageDiskSize
                messageDiskView.disk = winner
                messageLabel.text = " won"
            } else {
                messageDiskSizeConstraint.constant = 0
                messageLabel.text = "Tied"
            }
        }
    }
    
    func playerControl(of side: Disk) -> UISegmentedControl {
        switch side {
        case .dark: return darkPlayerControl
        case .light: return lightPlayerControl
        }
    }
    
    func side(of playerControl: UISegmentedControl) -> Disk {
        if playerControl === darkPlayerControl {
            return .dark
        } else if playerControl === lightPlayerControl {
            return .light
        } else {
            preconditionFailure()
        }
    }
}

// MARK: Interactions

extension ViewController {
    @IBAction func pressResetButton(_ sender: UIButton) {
        let alertController = UIAlertController(
            title: "Confirmation",
            message: "Do you really want to reset the game?",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in })
        alertController.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.newGame()
        })
        present(alertController, animated: true)
    }
    
    @IBAction func changePlayerControlSegment(_ sender: UISegmentedControl) {
        let side = self.side(of: sender)
        
        switch side {
        case .dark:
            if let canceller = darkPlayerCanceller {
                canceller.cancel()
            }
        case .light:
            if let canceller = lightPlayerCanceller {
                canceller.cancel()
            }
        }
        
        if !isAnimating, side == turn, case .computer = Player(rawValue: sender.selectedSegmentIndex)! {
            playTurnOfComputer()
        }
    }
}

extension ViewController: BoardViewDelegate {
    func boardView(_ boardView: BoardView, didSelectCellAtX x: Int, y: Int) {
        guard let turn = turn else { return }
        let playerControl = self.playerControl(of: turn)
        if isAnimating { return }
        guard case .manual = Player(rawValue: playerControl.selectedSegmentIndex)! else { return }
        // try? because doing nothing when an error occurs
        try? placeDisk(turn, atX: x, y: y, animated: true) { [weak self] _ in
            self?.nextTurn()
        }
    }
}

// MARK: Save and Load

extension ViewController {
    private var path: String {
        (NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first! as NSString).appendingPathComponent("Game")
    }
    
    func save() throws {
        var output: String = turn.symbol + "\n"
        
        for y in boardView.yRange {
            for x in boardView.xRange {
                output += boardView.diskAt(x: x, y: y).symbol
            }
            output += "\n"
        }
        
        do {
            try output.write(toFile: path, atomically: true, encoding: .utf8)
        } catch let error {
            throw FileIOError.read(path: path, cause: error)
        }
    }
    
    func load() throws {
        let input = try String(contentsOfFile: path, encoding: .utf8)
        
        var lines: ArraySlice<Substring> = input.split(separator: "\n")[...]
        
        let turn: Disk?
        do {
            guard let line = lines.popFirst() else {
                throw FileIOError.read(path: path, cause: nil)
            }
            turn = Optional<Disk>(symbol: line).flatMap { $0 }
        }
        
        guard lines.count == boardView.height else {
            throw FileIOError.read(path: path, cause: nil)
        }
        var disks: [Disk?] = []
        while let line = lines.popFirst() {
            let row: [Disk?] = line.map { character in Disk?(symbol: "\(character)").flatMap { $0 } }
            guard row.count == boardView.width else {
                throw FileIOError.read(path: path, cause: nil)
            }
            disks.append(contentsOf: row)
        }

        newGame { outTurn, boardView in
            outTurn = turn
            
            var i = 0
            for y in boardView.yRange {
                for x in boardView.xRange {
                    boardView.setDisk(disks[i], atX: x, y: y, animated: false)
                    i += 1
                }
            }
        }
    }
    
    enum FileIOError: Error {
        case write(path: String, cause: Error?)
        case read(path: String, cause: Error?)
    }
}

// MARK: Additional types

extension ViewController {
    enum Player: Int {
        case manual = 0
        case computer = 1
    }
}

final class Canceller {
    private(set) var isCancelled: Bool = false
    private let body: (() -> Void)?
    
    init(_ body: (() -> Void)?) {
        self.body = body
    }
    
    func cancel() {
        if isCancelled { return }
        isCancelled = true
        body?()
    }
}

struct DiskPlacementError: Error {
    let disk: Disk
    let x: Int
    let y: Int
}

// MARK: File-private extensions

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

import UIKit

class ViewController: UIViewController {
    @IBOutlet private var boardView: BoardView!
    @IBOutlet private var messageDiskView: DiskView!
    @IBOutlet private var messageLabel: UILabel!
    @IBOutlet private var messageDiskSizeConstraint: NSLayoutConstraint!
    @IBOutlet private var playerControls: [UISegmentedControl]!
    @IBOutlet private var countLabels: [UILabel]!
    @IBOutlet private var playerActivityIndicators: [UIActivityIndicatorView]!
    private var messageDiskSize: CGFloat! // to store the size designated in the storyboard
    private var animationState: AnimationState = .init()
    private var reversiState: ReversiState = .init()

    override func viewDidLoad() {
        super.viewDidLoad()
        boardView.delegate = self
        messageDiskSize = messageDiskSizeConstraint.constant
        loadGame()
    }
    
    private var viewHasAppeared: Bool = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if viewHasAppeared { return }
        viewHasAppeared = true
        waitForPlayer()
    }
}

// MARK: Game management

extension ViewController {
    func saveGame() {
        do {
            try reversiState.saveGame()
        } catch let e {
            dump(e)
            showAlter(title: "Error occurred.", message: "Cannot save games.")
        }
    }

    func loadGame() {
        do {
            try reversiState.loadGame()
            updateDisksForInitial()
            updatePlayerControls(reversiState)
            updateMessageViews()
            updateCountLabels()
        } catch let e {
            dump(e)
            showAlter(title: "Error occurred.", message: "Cannot load games.")
        }
    }

    func newGame() {
        do {
            try reversiState.newGame()
            updateDisksForInitial()
            updatePlayerControls(reversiState)
            updateMessageViews()
            updateCountLabels()
        } catch let e {
            dump(e)
            showAlter(title: "Error occurred.", message: "Cannot new games.")
        }
    }

    func nextTurn() {
        guard let turn = reversiState.nextTurn() else { return }

        func showCannotPlaceDiskAlert() {
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

        if reversiState.validMoves(for: turn).isEmpty {
            if reversiState.validMoves(for: turn.flipped).isEmpty {
                reversiState.gameover()
                updateMessageViews()
            } else {
                updateMessageViews()
                showCannotPlaceDiskAlert()
            }
        } else {
            updateMessageViews()
            waitForPlayer()
        }
    }

    func waitForPlayer() {
        switch reversiState.currentPlayer {
        case .manual:
            break
        case .computer:
            playTurnOfComputer()
        }
    }
    
    func playTurnOfComputer() {
        guard case .turn(let turn) = reversiState.currentGameState else { preconditionFailure() }
        let (x, y) = reversiState.validMoves(for: turn).randomElement()!

        playerActivityIndicators[turn.index].startAnimating()
        
        let cleanUp: AnimationState.CleanUp = { [weak self] in
            self?.playerActivityIndicators[turn.index].stopAnimating()
        }
        let canceller = animationState.createAnimationCanceller(at: turn, cleanUp: cleanUp)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            if canceller.isCancelled { return }
            canceller.cancel()

            self.placeDisk(player: .computer, disk: turn, atX: x, y: y, animated: true) { [weak self] _ in
                self?.nextTurn()
            }
        }
    }

    /// - Parameter completion: A closure to be executed when the animation sequence ends.
    ///     This closure has no return value and takes a single Boolean argument that indicates
    ///     whether or not the animations actually finished before the completion handler was called.
    ///     If `animated` is `false`,  this closure is performed at the beginning of the next run loop cycle. This parameter may be `nil`.
    /// - Throws: `DiskPlacementError` if the `disk` cannot be placed at (`x`, `y`).
    func placeDisk(player: Player, disk: Disk, atX x: Int, y: Int, animated isAnimated: Bool, completion: ((Bool) -> Void)? = nil) {
        do {
            let diskCoordinates = try reversiState.flippedDiskCoordinatesByPlacingDisk(disk, atX: x, y: y)
            updateDisks(disk, atX: x, y: y, diskCoordinates: diskCoordinates, animated: isAnimated, completion: completion)
        } catch let e as ReversiState.DiskPlacementError {
            switch player {
            case .manual:
                break // because doing nothing when an error occurs
            case .computer:
                dump(e)
                showAlter(title: "Error occurred.", message: "Cannot place \(e.disk.name) disk at x: \(e.x) y: \(e.y)")
            }
        } catch let e {
            dump(e)
            showAlter(title: "Error occurred.", message: "Unknown error occurred.")
        }
    }
}

// MARK: Views

extension ViewController {
    /* Board */
    func updateDisksForInitial() {
        for y in BoardConstant.yRange {
            for x in BoardConstant.xRange {
                let disk = reversiState.diskAt(x: x, y: y)
                boardView.updateDisk(disk, atX: x, y: y, animated: false)
            }
        }
    }

    func updateDisk(_ disk: Disk?, atX x: Int, y: Int, animated: Bool, completion: ((Bool) -> Void)? = nil) {
        reversiState.setDisk(disk, atX: x, y: y)
        boardView.updateDisk(disk, atX: x, y: y, animated: animated, completion: completion)
    }

    func updateDisks(_ disk: Disk, atX x: Int, y: Int, diskCoordinates: [(Int, Int)], animated isAnimated: Bool, completion: ((Bool) -> Void)? = nil) {
        if isAnimated {
            animationState.createAnimationCanceller()
            updateDisksWithAnimation(at: [(x, y)] + diskCoordinates, to: disk) { [weak self] finished in
                guard let self = self else { return }
                if self.animationState.isCancelled { return }
                self.animationState.cancel()

                completion?(finished)
                self.saveGame()
                self.updateCountLabels()
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.updateDisk(disk, atX: x, y: y, animated: false)
                for (x, y) in diskCoordinates {
                    self.updateDisk(disk, atX: x, y: y, animated: false)
                }
                completion?(true)
                self.saveGame()
                self.updateCountLabels()
            }
        }
    }

    private func updateDisksWithAnimation<C: Collection>(at coordinates: C, to disk: Disk, completion: @escaping (Bool) -> Void)
        where C.Element == (Int, Int)
    {
        guard let (x, y) = coordinates.first else {
            completion(true)
            return
        }

        updateDisk(disk, atX: x, y: y, animated: true) { [weak self] finished in
            guard let self = self else { return }
            if self.animationState.isCancelled { return }
            if finished {
                self.updateDisksWithAnimation(at: coordinates.dropFirst(), to: disk, completion: completion)
            } else {
                for (x, y) in coordinates {
                    self.updateDisk(disk, atX: x, y: y, animated: false)
                }
                completion(false)
            }
        }
    }

    /* Game */
    func updatePlayerControls(_ reversiState: ReversiState) {
        for side in Disk.sides {
            playerControls[side.index].selectedSegmentIndex = reversiState.player(at: side).rawValue
        }
    }

    func updateCountLabels() {
        for side in Disk.sides {
            countLabels[side.index].text = "\(reversiState.count(of: side))"
        }
    }
    
    func updateMessageViews() {
        switch reversiState.currentGameState {
        case .turn(let side):
            messageDiskSizeConstraint.constant = messageDiskSize
            messageDiskView.disk = side
            messageLabel.text = "'s turn"
        case .gameOverWon(let winner):
            messageDiskSizeConstraint.constant = messageDiskSize
            messageDiskView.disk = winner
            messageLabel.text = " won"
        case .gameOverTied:
            messageDiskSizeConstraint.constant = 0
            messageLabel.text = "Tied"
        }
    }

    func showAlter(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.newGame()
        })
        present(alertController, animated: true)
    }
}

// MARK: Inputs

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
            self.animationState.cancelAll()
            self.newGame()
            self.waitForPlayer()
        })
        present(alertController, animated: true)
    }
    
    @IBAction func changePlayerControlSegment(_ sender: UISegmentedControl) {
        let side: Disk = Disk(index: playerControls.firstIndex(of: sender)!)
        let player = sender.convertToPlayer
        reversiState.setPlayer(player: player, at: side)
        saveGame()
        animationState.cancel(at: side)
        if !animationState.isAnimating && reversiState.canPlayTurnOfComputer(at: side) {
            playTurnOfComputer()
        }
    }
}

extension ViewController: BoardViewDelegate {
    func boardView(_ boardView: BoardView, didSelectCellAtX x: Int, y: Int) {
        guard case .turn(let turn) = reversiState.currentGameState else { return }
        if animationState.isAnimating { return }
        guard case .manual = reversiState.currentPlayer else { return }
        placeDisk(player: .manual, disk: turn, atX: x, y: y, animated: true) { [weak self] _ in
            self?.nextTurn()
        }
    }
}

// MARK: Additional types

extension UISegmentedControl {
    fileprivate var convertToPlayer: Player {
        switch selectedSegmentIndex {
        case 0: return .manual
        case 1: return .computer
        default: preconditionFailure()
        }
    }
}

extension Disk {
    var name: String {
        switch self {
        case .dark: return "dark"
        case .light: return "light"
        }
    }
}

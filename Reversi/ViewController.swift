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
        boardView.setUp(with: reversiState.constant)

        do {
            try loadGame()
        } catch _ {
            do {
                try newGame()
            } catch _ {

            }
        }
    }
    
    private var viewHasAppeared: Bool = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if viewHasAppeared { return }
        viewHasAppeared = true
        waitForPlayer()
    }
}

// MARK: Reversi logics

extension ViewController {
    /// - Parameter completion: A closure to be executed when the animation sequence ends.
    ///     This closure has no return value and takes a single Boolean argument that indicates
    ///     whether or not the animations actually finished before the completion handler was called.
    ///     If `animated` is `false`,  this closure is performed at the beginning of the next run loop cycle. This parameter may be `nil`.
    /// - Throws: `DiskPlacementError` if the `disk` cannot be placed at (`x`, `y`).
    func placeDisk(_ disk: Disk, atX x: Int, y: Int, animated isAnimated: Bool, completion: ((Bool) -> Void)? = nil) throws {
        let diskCoordinates = reversiState.flippedDiskCoordinatesByPlacingDisk(disk, atX: x, y: y)
        if diskCoordinates.isEmpty {
            throw DiskPlacementError(disk: disk, x: x, y: y)
        }
        
        if isAnimated {
            animationState.createAnimationCanceller()
            animateSettingDisks(at: [(x, y)] + diskCoordinates, to: disk) { [weak self] finished in
                guard let self = self else { return }
                if self.animationState.isCancelled { return }
                self.animationState.cancel()

                completion?(finished)
                try? self.saveGame()
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
                try? self.saveGame()
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

        updateDisk(disk, atX: x, y: y, animated: true) { [weak self] finished in
            guard let self = self else { return }
            if self.animationState.isCancelled { return }
            if finished {
                self.animateSettingDisks(at: coordinates.dropFirst(), to: disk, completion: completion)
            } else {
                for (x, y) in coordinates {
                    self.updateDisk(disk, atX: x, y: y, animated: false)
                }
                completion(false)
            }
        }
    }
}

// MARK: Game management

extension ViewController {
    func saveGame() throws {
        try reversiState.saveGame()
    }

    func loadGame() throws {
        try reversiState.loadGame()
        updateBoard()
        updatePlayerControls(reversiState)
        updateMessageViews()
        updateCountLabels()
    }

    func newGame() throws {
        try reversiState.newGame()
        updateBoard()
        updatePlayerControls(reversiState)
        updateMessageViews()
        updateCountLabels()
    }

    func nextTurn() {
        guard !reversiState.isGameOver else { return }
        guard let turn = reversiState.nextTurn() else { return }

        if reversiState.validMoves(for: turn).isEmpty {
            if reversiState.validMoves(for: turn.flipped).isEmpty {
                reversiState.gameover()
                updateMessageViews()
            } else {
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
            updateMessageViews()
            waitForPlayer()
        }
    }

    func waitForPlayer() {
        switch reversiState.playerThisTurn {
        case .manual:
            break
        case .computer:
            playTurnOfComputer()
        }
    }
    
    func playTurnOfComputer() {
        guard let turn = reversiState.turn else { preconditionFailure() }
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

            try! self.placeDisk(turn, atX: x, y: y, animated: true) { [weak self] _ in
                self?.nextTurn()
            }
        }
    }
}

// MARK: Views

extension ViewController {
    /* Board */
    func updateDisk(_ disk: Disk?, atX x: Int, y: Int, animated: Bool, completion: ((Bool) -> Void)? = nil) {
        guard let index = reversiState.constant.convertPositionToIndex(x: x, y: y) else {
            preconditionFailure()
        }
        reversiState.boardState.setDisk(disk, atX: x, y: y)
        boardView.updateDisk(disk, at: index, animated: animated, completion: completion)
    }

    func updateBoard() {
        let boardState = reversiState.boardState
        let constant = reversiState.constant
        for y in constant.yRange {
            for x in constant.xRange {
                let disk = boardState.diskAt(x: x, y: y)
                let index = constant.convertPositionToIndex(x: x, y: y)!
                boardView.updateDisk(disk, at: index, animated: false)
            }
        }
    }

    /* Game */
    func updatePlayerControls(_ reversiState: ReversiState) {
        for side in Disk.sides {
            playerControls[side.index].selectedSegmentIndex = reversiState.player(at: side.index).rawValue
        }
    }

    func updateCountLabels() {
        for side in Disk.sides {
            countLabels[side.index].text = "\(reversiState.boardState.count(of: side))"
        }
    }
    
    func updateMessageViews() {
        switch reversiState.turn {
        case .some(let side):
            messageDiskSizeConstraint.constant = messageDiskSize
            messageDiskView.disk = side
            messageLabel.text = "'s turn"
        case .none:
            if let winner = reversiState.boardState.sideWithMoreDisks() {
                messageDiskSizeConstraint.constant = messageDiskSize
                messageDiskView.disk = winner
                messageLabel.text = " won"
            } else {
                messageDiskSizeConstraint.constant = 0
                messageLabel.text = "Tied"
            }
        }
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
            do {
                try self.newGame()
                self.waitForPlayer()
            } catch _ {

            }
        })
        present(alertController, animated: true)
    }
    
    @IBAction func changePlayerControlSegment(_ sender: UISegmentedControl) {
        let side: Disk = Disk(index: playerControls.firstIndex(of: sender)!)
        let player = sender.convertToPlayer
        reversiState.setPlayer(player: player, at: side.index)
        try? saveGame()
        animationState.cancel(at: side)
        if !animationState.isAnimating && reversiState.canPlayTurnOfComputer(at: side) {
            playTurnOfComputer()
        }
    }
}

extension ViewController: BoardViewDelegate {
    func boardView(_ boardView: BoardView, didSelectCellAtX x: Int, y: Int) {
        guard let turn = reversiState.turn else { return }
        if animationState.isAnimating { return }
        guard case .manual = reversiState.playerThisTurn else { return }
        // try? because doing nothing when an error occurs
        try? placeDisk(turn, atX: x, y: y, animated: true) { [weak self] _ in
            self?.nextTurn()
        }
    }
}

// MARK: Additional types

struct DiskPlacementError: Error {
    let disk: Disk
    let x: Int
    let y: Int
}

extension UISegmentedControl {
    fileprivate var convertToPlayer: Player {
        switch selectedSegmentIndex {
        case 0: return .manual
        case 1: return .computer
        default: preconditionFailure()
        }
    }
}

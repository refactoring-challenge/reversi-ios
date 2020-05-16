import UIKit
import Combine

class ViewController: UIViewController {
    @IBOutlet private var boardView: BoardView!
    
    @IBOutlet private var messageDiskView: DiskView!
    @IBOutlet private var messageLabel: UILabel!
    @IBOutlet private var messageDiskSizeConstraint: NSLayoutConstraint!
    /// Storyboard 上で設定されたサイズを保管します。
    /// 引き分けの際は `messageDiskView` の表示が必要ないため、
    /// `messageDiskSizeConstraint.constant` を `0` に設定します。
    /// その後、新しいゲームが開始されたときに `messageDiskSize` を
    /// 元のサイズで表示する必要があり、
    /// その際に `messageDiskSize` に保管された値を使います。
    private var messageDiskSize: CGFloat!
    
    @IBOutlet private var playerControls: [UISegmentedControl]!
    @IBOutlet private var countLabels: [UILabel]!
    @IBOutlet private var playerActivityIndicators: [UIActivityIndicatorView]!
    
    private var animationCanceller: Canceller?
    private var isAnimating: Bool { animationCanceller != nil }

    private lazy var gameManager = GameManager(boardView: boardView)
    private var cancellables: Set<AnyCancellable> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        boardView.delegate = self
        messageDiskSize = messageDiskSizeConstraint.constant

        gameManager.onStateChanged
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                self.updateMessageViews()
                self.updateCountLabels()
            }
            .store(in: &cancellables)

        gameManager.onStartThinking
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                self.playerActivityIndicators[$0.index].startAnimating()
            }
            .store(in: &cancellables)

        gameManager.onFinishThinking
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                self.playerActivityIndicators[$0.index].stopAnimating()
            }
            .store(in: &cancellables)

        gameManager.onMakeMove
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                let cleanUp: () -> Void = { [weak self] in
                    self?.animationCanceller = nil
                }
                self.animationCanceller = Canceller(cleanUp)
                self.animateSettingDisks(at: $0.coordinates, to: $0.disk) { [weak self] isFinished in
                    guard let self = self else { return }
                    guard let canceller = self.animationCanceller else { return }
                    if canceller.isCancelled { return }
                    cleanUp()

                    try? self.gameManager.saveGame()
                }
            }
            .store(in: &cancellables)

        gameManager.onPlayerPass
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                let alertController = UIAlertController(
                    title: "Pass",
                    message: "Cannot place a disk.",
                    preferredStyle: .alert
                )
                alertController.addAction(UIAlertAction(title: "Dismiss", style: .default) { [weak self] _ in
                    self?.gameManager.nextTurn()
                })
                self.present(alertController, animated: true)
            }
            .store(in: &cancellables)
        
        do {
            try gameManager.loadGame()
        } catch _ {
            gameManager.newGame()
        }
    }
    
    private var viewHasAppeared: Bool = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if viewHasAppeared { return }
        viewHasAppeared = true
        gameManager.waitForPlayer()
    }
}

extension ViewController {    
    /// `coordinates` で指定されたセルに、アニメーションしながら順番に `disk` を置く。
    /// `coordinates` から先頭の座標を取得してそのセルに `disk` を置き、
    /// 残りの座標についてこのメソッドを再帰呼び出しすることで処理が行われる。
    /// すべてのセルに `disk` が置けたら `completion` ハンドラーが呼び出される。
    private func animateSettingDisks<C: Collection>(at coordinates: C, to disk: Disk, completion: @escaping (Bool) -> Void)
        where C.Element == (Int, Int)
    {
        guard let (x, y) = coordinates.first else {
            completion(true)
            return
        }
        
        let animationCanceller = self.animationCanceller!
        boardView.setDisk(disk, atX: x, y: y, animated: true) { [weak self] isFinished in
            guard let self = self else { return }
            if animationCanceller.isCancelled { return }
            if isFinished {
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

extension ViewController {
    /// 各プレイヤーの獲得したディスクの枚数を表示します。
    func updateCountLabels() {
        for side in Disk.sides {
            countLabels[side.index].text = "\(gameManager.countDisks(of: side))"
        }
    }
    
    /// 現在の状況に応じてメッセージを表示します。
    func updateMessageViews() {
        switch gameManager.gameState {
        case .playing(let side):
            messageDiskSizeConstraint.constant = messageDiskSize
            messageDiskView.disk = side
            messageLabel.text = "'s turn"
        case .finished(let winner):
            if let winner = winner {
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

extension ViewController {
    /// リセットボタンが押された場合に呼ばれるハンドラーです。
    /// アラートを表示して、ゲームを初期化して良いか確認し、
    /// "OK" が選択された場合ゲームを初期化します。
    @IBAction func pressResetButton(_ sender: UIButton) {
        let alertController = UIAlertController(
            title: "Confirmation",
            message: "Do you really want to reset the game?",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in })
        alertController.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            self.animationCanceller?.cancel()
            self.animationCanceller = nil
            
            self.gameManager.newGame()
            self.gameManager.waitForPlayer()
        })
        present(alertController, animated: true)
    }
    
    /// プレイヤーのモードが変更された場合に呼ばれるハンドラーです。
    @IBAction func changePlayerControlSegment(_ sender: UISegmentedControl) {
        let side: Disk = Disk(index: playerControls.firstIndex(of: sender)!)
        
        try? gameManager.saveGame()
        if !isAnimating {
            gameManager.changePlayerMode(for: side, mode: sender.selectedSegmentIndex)
        }
    }
}

extension ViewController: BoardViewDelegate {
    /// `boardView` の `x`, `y` で指定されるセルがタップされたときに呼ばれます。
    /// - Parameter boardView: セルをタップされた `BoardView` インスタンスです。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    func boardView(_ boardView: BoardView, didSelectCellAtX x: Int, y: Int) {
        if isAnimating { return }
        // try? because doing nothing when an error occurs
        try? gameManager.placeDisk(atX: x, y: y)
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

import UIKit

class ViewController: UIViewController {
    @IBOutlet private var boardView: BoardView!
    
    @IBOutlet private var messageDiskView: DiskView!
    @IBOutlet private var messageLabel: UILabel!
    @IBOutlet private var messageDiskSizeConstraint: NSLayoutConstraint!
    private var messageDiskSize: CGFloat!
    
    @IBOutlet private var darkPlayerControl: UISegmentedControl!
    @IBOutlet private var darkCountLabel: UILabel!
    
    @IBOutlet private var lightPlayerControl: UISegmentedControl!
    @IBOutlet private var lightCountLabel: UILabel!
    
    private var turn: Disk? = .dark

    override func viewDidLoad() {
        super.viewDidLoad()
        
        boardView.delegate = self
        messageDiskSize = messageDiskSizeConstraint.constant
        
        updateViews()
    }
    
    func startGame() {
        boardView.reset()
        turn = .dark
        updateViews()
    }
    
    func updateViews() {
        switch turn {
        case .some(let disk):
            messageDiskSizeConstraint.constant = messageDiskSize
            messageDiskView.disk = disk
            messageLabel.text = "'s turn"
        case .none:
            let darkCount = count(of: .dark)
            let lightCount = count(of: .light)
            if darkCount == lightCount {
                messageDiskSizeConstraint.constant = 0
                messageLabel.text = "Draw"
            } else {
                let winner: Disk = darkCount > lightCount ? .dark : .light
                messageDiskSizeConstraint.constant = messageDiskSize
                messageDiskView.disk = winner
                messageLabel.text = " won"
            }
        }
        
        darkCountLabel.text = "\(count(of: .dark))"
        lightCountLabel.text = "\(count(of: .light))"
    }
    
    @IBAction func pressRestButton(_ sender: UIButton) {
        let alertController = UIAlertController(
            title: "Confirmation",
            message: "Do you really want to reset the game?",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in })
        alertController.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in self?.startGame() })
        present(alertController, animated: true)
    }
}

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
}

extension ViewController: BoardViewDelegate {
    func boardView(_ boardView: BoardView, didSelectCellAtX x: Int, y: Int) {
//        boardView.setDisk([Disk.dark, Disk.light, nil].randomElement()!, atX: x, y: y, animated: true)
        if let disk = boardView.diskAt(x: x, y: y) {
            boardView.setDisk(Bool.random() ? disk.reversed : nil, atX: x, y: y, animated: true)
        } else {
            boardView.setDisk(Bool.random() ? .dark : .light, atX: x, y: y, animated: true)
        }
    }
}


import UIKit

class ViewController: UIViewController {
    @IBOutlet private var boardView: BoardView!
    
    @IBOutlet private var messageDiskView: DiskView!
    @IBOutlet private var messageLabel: UILabel!
    
    @IBOutlet private var darkPlayerControl: UISegmentedControl!
    @IBOutlet private var darkCountLabel: UILabel!
    
    @IBOutlet private var lightPlayerControl: UISegmentedControl!
    @IBOutlet private var lightCountLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        boardView.delegate = self
    }
    
    @IBAction func pressRestButton(_ sender: UIButton) {
        print("The reset button is pressed.")
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


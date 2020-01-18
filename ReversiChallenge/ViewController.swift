import UIKit

class ViewController: UIViewController {
    @IBOutlet private var boardView: BoardView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        boardView.delegate = self
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


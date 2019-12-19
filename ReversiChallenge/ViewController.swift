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
        boardView.setDisk(.light, atX: x, y: y, animated: true)
    }
}


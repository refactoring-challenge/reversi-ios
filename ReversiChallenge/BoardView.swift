import UIKit

private let lineWidth: CGFloat = 2

public class BoardView: UIView {
    private var cellViews: [CellView] = []
    private var actions: [CellSelectionAction] = []
    
    public let width: Int = 8
    public let height: Int = 8
    
    public let xRange: Range<Int>
    public let yRange: Range<Int>
    
    public weak var delegate: BoardViewDelegate?
    
    override public init(frame: CGRect) {
        xRange = 0 ..< width
        yRange = 0 ..< height
        super.init(frame: frame)
        setUp()
    }
    
    required public init?(coder: NSCoder) {
        xRange = 0 ..< width
        yRange = 0 ..< height
        super.init(coder: coder)
        setUp()
    }
    
    private func setUp() {
        self.backgroundColor = UIColor(named: "DarkColor")!
        
        let cellViews: [CellView] = (0 ..< (width * height)).map { _ in
            let cellView = CellView()
            cellView.translatesAutoresizingMaskIntoConstraints = false
            return cellView
        }
        self.cellViews = cellViews
        
        cellViews.forEach(self.addSubview(_:))
        for i in cellViews.indices.dropFirst() {
            NSLayoutConstraint.activate([
                cellViews[0].widthAnchor.constraint(equalTo: cellViews[i].widthAnchor),
                cellViews[0].heightAnchor.constraint(equalTo: cellViews[i].heightAnchor),
            ])
        }
        
        NSLayoutConstraint.activate([
            cellViews[0].widthAnchor.constraint(equalTo: cellViews[0].heightAnchor),
        ])
        
        for y in yRange {
            for x in xRange {
                let topNeighborAnchor: NSLayoutYAxisAnchor
                if let cellView = cellViewAt(x: x, y: y - 1) {
                    topNeighborAnchor = cellView.bottomAnchor
                } else {
                    topNeighborAnchor = self.topAnchor
                }
                
                let leftNeighborAnchor: NSLayoutXAxisAnchor
                if let cellView = cellViewAt(x: x - 1, y: y) {
                    leftNeighborAnchor = cellView.rightAnchor
                } else {
                    leftNeighborAnchor = self.leftAnchor
                }
                
                let cellView = cellViewAt(x: x, y: y)!
                NSLayoutConstraint.activate([
                    cellView.topAnchor.constraint(equalTo: topNeighborAnchor, constant: lineWidth),
                    cellView.leftAnchor.constraint(equalTo: leftNeighborAnchor, constant: lineWidth),
                ])
                
                if y == height - 1 {
                    NSLayoutConstraint.activate([
                        self.bottomAnchor.constraint(equalTo: cellView.bottomAnchor, constant: lineWidth),
                    ])
                }
                if x == width - 1 {
                    NSLayoutConstraint.activate([
                        self.rightAnchor.constraint(equalTo: cellView.rightAnchor, constant: lineWidth),
                    ])
                }
            }
        }
        
        setDisk(.light, atX: width / 2 - 1, y: height / 2 - 1, animated: false)
        setDisk(.dark, atX: width / 2, y: height / 2 - 1, animated: false)
        setDisk(.dark, atX: width / 2 - 1, y: height / 2, animated: false)
        setDisk(.light, atX: width / 2, y: height / 2, animated: false)
        
        for y in yRange {
            for x in xRange {
                let cellView: CellView = cellViewAt(x: x, y: y)!
                let action = CellSelectionAction(boardView: self, x: x, y: y)
                actions.append(action) // To retain the `action`
                cellView.addTarget(action, action: #selector(action.selectCell), for: .touchUpInside)
            }
        }
    }
    
    private func cellViewAt(x: Int, y: Int) -> CellView? {
        guard xRange.contains(x) && yRange.contains(y) else { return nil }
        return cellViews[y * width + x]
    }
    
    func diskAt(x: Int, y: Int) -> Disk? {
        cellViewAt(x: x, y: y)?.disk
    }
    
    func setDisk(_ disk: Disk?, atX x: Int, y: Int, animated: Bool, completion: ((Bool) -> Void)? = nil) {
        guard let cellView = cellViewAt(x: x, y: y) else {
            preconditionFailure() // FIXME: Add a message.
        }
        cellView.setDisk(disk, animated: animated, completion: completion)
    }
}

public protocol BoardViewDelegate: AnyObject {
    func boardView(_ boardView: BoardView, didSelectCellAtX x: Int, y: Int)
}

private class CellSelectionAction: NSObject {
    private weak var boardView: BoardView?
    let x: Int
    let y: Int
    
    init(boardView: BoardView, x: Int, y: Int) {
        self.boardView = boardView
        self.x = x
        self.y = y
    }
    
    @objc func selectCell() {
        guard let boardView = boardView else { return }
        boardView.delegate?.boardView(boardView, didSelectCellAtX: x, y: y)
    }
}

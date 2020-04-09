import UIKit
import Logic

private let lineWidth: CGFloat = 2

public class BoardView: UIView {
    private var cellViews: [CellView] = []
    private var actions: [CellSelectionAction] = []
    weak var delegate: BoardViewDelegate?

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    private func setUp() {
        backgroundColor = UIColor(named: "DarkColor")!
        
        let cellViews: [CellView] = (0 ..< BoardConstant.squaresCount).map { _ in
            let cellView = CellView()
            cellView.translatesAutoresizingMaskIntoConstraints = false
            return cellView
        }
        self.cellViews = cellViews
        
        cellViews.forEach(addSubview(_:))
        for i in cellViews.indices.dropFirst() {
            NSLayoutConstraint.activate([
                cellViews[0].widthAnchor.constraint(equalTo: cellViews[i].widthAnchor),
                cellViews[0].heightAnchor.constraint(equalTo: cellViews[i].heightAnchor),
            ])
        }
        
        NSLayoutConstraint.activate([
            cellViews[0].widthAnchor.constraint(equalTo: cellViews[0].heightAnchor),
        ])
        
        for y in BoardConstant.yRange {
            for x in BoardConstant.xRange {
                let topNeighborAnchor: NSLayoutYAxisAnchor
                if let index = BoardConstant.convertPositionToIndex(x: x, y: y - 1) {
                    topNeighborAnchor = cellViews[index].bottomAnchor
                } else {
                    topNeighborAnchor = topAnchor
                }
                
                let leftNeighborAnchor: NSLayoutXAxisAnchor
                if let index = BoardConstant.convertPositionToIndex(x: x - 1, y: y) {
                    leftNeighborAnchor = cellViews[index].rightAnchor
                } else {
                    leftNeighborAnchor = leftAnchor
                }
                
                let cellView = cellViews[BoardConstant.convertPositionToIndex(x: x, y: y)!]
                NSLayoutConstraint.activate([
                    cellView.topAnchor.constraint(equalTo: topNeighborAnchor, constant: lineWidth),
                    cellView.leftAnchor.constraint(equalTo: leftNeighborAnchor, constant: lineWidth),
                ])
                
                if y == BoardConstant.height - 1 {
                    NSLayoutConstraint.activate([
                        bottomAnchor.constraint(equalTo: cellView.bottomAnchor, constant: lineWidth),
                    ])
                }
                if x == BoardConstant.width - 1 {
                    NSLayoutConstraint.activate([
                        rightAnchor.constraint(equalTo: cellView.rightAnchor, constant: lineWidth),
                    ])
                }
            }
        }
       
        for y in BoardConstant.yRange {
            for x in BoardConstant.xRange {
                let index = BoardConstant.convertPositionToIndex(x: x, y: y)!
                let cellView: CellView = cellViews[index]
                let action = CellSelectionAction(boardView: self, x: x, y: y)
                actions.append(action) // To retain the `action`
                cellView.addTarget(action, action: #selector(action.selectCell), for: .touchUpInside)
            }
        }
    }

    func updateDisk(_ disk: Disk?, atX x: Int, y: Int, animated: Bool, completion: ((Bool) -> Void)? = nil) {
        guard let index = BoardConstant.convertPositionToIndex(x: x, y: y) else { preconditionFailure() }
        cellViews[index].setDisk(disk, animated: animated, completion: completion)
    }
}

protocol BoardViewDelegate: AnyObject {
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

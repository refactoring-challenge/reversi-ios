import UIKit

private let lineWidth: CGFloat = 2

public class BoardView: UIView {
    private var cellViews: [CellView] = []
    
    private let width: Int = 8
    private let height: Int = 8
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }
    
    required public init?(coder: NSCoder) {
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
        
        for y in 0 ..< height {
            for x in 0 ..< width {
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
    }
    
    private func cellViewAt(x: Int, y: Int) -> CellView? {
        guard (0 ..< width).contains(x) && (0 ..< height).contains(y) else { return nil }
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

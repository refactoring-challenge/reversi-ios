import ReversiCore
import ReactiveSwift



public protocol BoardViewHandleProtocol {
    var coordinateDidSelect: ReactiveSwift.Signal<Coordinate, Never> { get }
    func set(disk: Disk?, at: Coordinate, animated: Bool)
    func set(disk: Disk?, at: Coordinate, animated: Bool, _ completion: ((Bool) -> Void)?)
    func cancelAllAnimations()
}



extension BoardViewHandleProtocol {
    public func set(board: Board, animated: Bool, _ completion: ((Bool) -> Void)? = nil) {
        Coordinate.allCases.forEach { coordinate in
            self.set(disk: board[coordinate], at: coordinate, animated: animated, completion)
        }
    }
}



public class BoardViewHandle: BoardViewHandleProtocol {
    public let coordinateDidSelect: ReactiveSwift.Signal<Coordinate, Never>
    private let coordinateDidSelectObserver: ReactiveSwift.Signal<Coordinate, Never>.Observer

    private let boardView: BoardView


    public init(boardView: BoardView) {
        self.boardView = boardView
        (self.coordinateDidSelect, self.coordinateDidSelectObserver) = ReactiveSwift.Signal<Coordinate, Never>.pipe()

        boardView.delegate = self
    }


    public func set(disk: Disk?, at coordinate: Coordinate, animated: Bool) {
        self.set(disk: disk, at: coordinate, animated: animated, nil)
    }


    public func set(disk: Disk?, at coordinate: Coordinate, animated: Bool, _ completion: ((Bool) -> ())?) {
        self.boardView.setDisk(disk, atX: coordinate.x.rawValue - 1, y: coordinate.y.rawValue - 1, animated: animated)
    }


    public func cancelAllAnimations() {
        self.boardView.layer.removeAllAnimations()
    }
}



extension BoardViewHandle: BoardViewDelegate {
    public func boardView(_ boardView: BoardView, didSelectCellAtX x: Int, y: Int) {
        guard let coordinateX = CoordinateX(rawValue: x + 1) else { return }
        guard let coordinateY = CoordinateY(rawValue: y + 1) else { return }
        self.coordinateDidSelectObserver.send(value: Coordinate(x: coordinateX, y: coordinateY))
    }
}

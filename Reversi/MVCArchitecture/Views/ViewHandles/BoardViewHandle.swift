import ReversiCore
import ReactiveSwift



public protocol BoardViewHandleProtocol {
    var coordinateDidSelect: ReactiveSwift.Signal<Coordinate, Never> { get }

    func apply(by request: BoardAnimationRequest)
}



public protocol BoardAnimationHandleProtocol {
    var animationDidComplete: ReactiveSwift.Signal<BoardAnimationRequest, Never> { get }
}



public class BoardViewHandle: BoardViewHandleProtocol, BoardAnimationHandleProtocol {
    public let coordinateDidSelect: ReactiveSwift.Signal<Coordinate, Never>
    public let animationDidComplete: ReactiveSwift.Signal<BoardAnimationRequest, Never>

    private let coordinateDidSelectObserver: ReactiveSwift.Signal<Coordinate, Never>.Observer
    private let animationDidCompleteObserver: ReactiveSwift.Signal<BoardAnimationRequest, Never>.Observer

    private let boardView: BoardView


    public init(boardView: BoardView) {
        self.boardView = boardView

        (self.coordinateDidSelect, self.coordinateDidSelectObserver) =
            ReactiveSwift.Signal<Coordinate, Never>.pipe()

        (self.animationDidComplete, self.animationDidCompleteObserver) =
            ReactiveSwift.Signal<BoardAnimationRequest, Never>.pipe()

        boardView.delegate = self
    }


    public func apply(by request: BoardAnimationRequest) {
        switch request {
        case .shouldSyncImmediately(board: let board):
            self.syncImmediately(to: board)
        case .shouldAnimate(disk: let disk, at: let coordinate, shouldSyncBefore: let board):
            self.syncImmediately(to: board)
            self.animate(disk: disk, at: coordinate, shouldSyncBefore: board)
        }
    }


    private func syncImmediately(to board: Board) {
        self.boardView.layer.removeAllAnimations()
        Coordinate.allCases.forEach { coordinate in
            self.set(disk: board[coordinate], at: coordinate, animated: false, completion: nil)
        }
        self.animationDidCompleteObserver.send(value: .shouldSyncImmediately(board: board))
    }


    private func animate(disk: Disk, at coordinate: Coordinate, shouldSyncBefore board: Board) {
        self.set(disk: disk, at: coordinate, animated: true) { isFinished in
            if isFinished {
                self.animationDidCompleteObserver.send(value: .shouldAnimate(
                    disk: disk,
                    at: coordinate,
                    shouldSyncBefore: board
                ))
            }
        }
    }


    private func set(disk: Disk?, at coordinate: Coordinate, animated: Bool, completion: ((Bool) -> Void)?) {
        self.boardView.setDisk(
            disk,
            atX: coordinate.x.rawValue - 1,
            y: coordinate.y.rawValue - 1,
            animated: animated,
            completion: completion
        )
    }
}



extension BoardViewHandle: BoardViewDelegate {
    public func boardView(_ boardView: BoardView, didSelectCellAtX x: Int, y: Int) {
        guard let coordinateX = CoordinateX(rawValue: x + 1) else { return }
        guard let coordinateY = CoordinateY(rawValue: y + 1) else { return }
        self.coordinateDidSelectObserver.send(value: Coordinate(x: coordinateX, y: coordinateY))
    }
}

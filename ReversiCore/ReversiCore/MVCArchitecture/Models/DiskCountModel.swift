import ReactiveSwift



public protocol DiskCountModelProtocol: class {
    var diskCountDidChange: ReactiveSwift.Property<DiskCount> { get }
}



public class DiskCountModel: DiskCountModelProtocol {
    public let diskCountDidChange: ReactiveSwift.Property<DiskCount>


    public init(observing boardModel: GameModel) {
        self.diskCountDidChange = boardModel.stateDidChange
            .map { gameModelState in gameModelState.gameState.board.countDisks() }
    }
}
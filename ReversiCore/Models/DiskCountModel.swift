import ReactiveSwift


public class DiskCountModel {
    private let diskCountDidChange: ReactiveSwift.Property<DiskCount>


    public init(observing boardModel: GameModel) {
        self.diskCountDidChange = boardModel.gameStateDidChange
            .map { gameState in gameState.board.countDisks() }
    }
}
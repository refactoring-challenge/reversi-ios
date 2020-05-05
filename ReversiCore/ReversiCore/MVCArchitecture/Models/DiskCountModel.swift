import ReactiveSwift



class DiskCountModel {
    private let diskCountDidChange: ReactiveSwift.Property<DiskCount>


    init(observing boardModel: GameModel) {
        self.diskCountDidChange = boardModel.stateDidChange
            .map { gameModelState in gameModelState.gameState.board.countDisks() }
    }
}
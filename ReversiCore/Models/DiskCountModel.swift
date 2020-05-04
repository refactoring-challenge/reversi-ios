import ReactiveSwift



class DiskCountModel {
    private let diskCountDidChange: ReactiveSwift.Property<DiskCount>


    init(observing boardModel: GameModel) {
        self.diskCountDidChange = boardModel.gameStateDidChange
            .map { gameState in gameState.board.countDisks() }
    }
}
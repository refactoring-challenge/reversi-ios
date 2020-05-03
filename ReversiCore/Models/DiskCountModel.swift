import ReactiveSwift


class DiskCountModel {
    private let diskCountDidChange: ReactiveSwift.Property<DiskCount>


    init(observing boardModel: BoardModel) {
        self.diskCountDidChange = boardModel.boardDidChange
            .map { board in board.countDisks() }
    }
}
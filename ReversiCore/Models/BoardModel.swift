import ReactiveSwift



class BoardModel {
    let didChange: ReactiveSwift.Property<Board<Disk?>>
    private let didChangeMutable: ReactiveSwift.MutableProperty<Board<Disk?>>


    init(board: Board<Disk?>) {
        let didChangeMutable = ReactiveSwift.MutableProperty<Board>(board)
        self.didChangeMutable = didChangeMutable
        self.didChange = ReactiveSwift.Property(didChangeMutable)
    }
}
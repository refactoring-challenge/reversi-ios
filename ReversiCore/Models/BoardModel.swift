import ReactiveSwift



protocol BoardModelProtocol {
    var turnDidChange: ReactiveSwift.Property<Turn> { get }
    var boardDidChange: ReactiveSwift.Property<Board<Disk?>> { get }
    var availableCoordinatesDidChange: ReactiveSwift.Property<Set<Coordinate>> { get }

    func placeDisk(at coordinate: Coordinate)
}



class BoardModel: BoardModelProtocol {
    // NOTE: This model has both a turn and board.
    // WHY: Because valid mutable operations to the board is depends on and affect to the turn and it must be
    //      atomic operations. Separating the properties into several smaller models is possible but it cannot
    //      ensure the atomicity without any aggregation wrapper models. And the wrapper model is not needed in
    //      the complexity.
    let turnDidChange: ReactiveSwift.Property<Turn>
    let boardDidChange: ReactiveSwift.Property<Board<Disk?>>
    let availableCoordinatesDidChange: ReactiveSwift.Property<Set<Coordinate>>


    private let turnDidChangeMutable: ReactiveSwift.MutableProperty<Turn>
    private let boardDidChangeMutable: ReactiveSwift.MutableProperty<Board<Disk?>>
    private var board: Board<Disk?> {
        get { self.boardDidChangeMutable.value }
        set { self.boardDidChangeMutable.value = newValue }
    }
    private var turn: Turn {
        get { self.turnDidChangeMutable.value }
        set { self.turnDidChangeMutable.value = newValue }
    }


    init(turn: Turn, board: Board<Disk?>) {
        let turnDidChangeMutable = ReactiveSwift.MutableProperty<Turn>(turn)
        self.turnDidChangeMutable = turnDidChangeMutable
        self.turnDidChange = ReactiveSwift.Property(turnDidChangeMutable)

        let boardDidChangeMutable = ReactiveSwift.MutableProperty<Board>(board)
        self.boardDidChangeMutable = boardDidChangeMutable
        self.boardDidChange = ReactiveSwift.Property(boardDidChangeMutable)

        self.availableCoordinatesDidChange = ReactiveSwift.Property
            .combineLatest(turnDidChangeMutable, boardDidChangeMutable)
            .map { (turn, board) in
                board.availableCoordinates(for: turn)
            }
    }


    func placeDisk(at coordinate: Coordinate) {
        self.board = self.board.updated(value: self.turn.disk, at: coordinate)
        self.turn = self.turn.next
    }
}
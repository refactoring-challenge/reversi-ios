struct LineContents: Equatable {
    let line: Line
    let disks: [Disk?]


    init(board: Board, line: Line) {
        self.line = line
        self.disks = line.coordinates.map { coordinate in board[coordinate] }
    }


    init?(expandingTo base: LineContents, on board: Board) {
        guard let line = base.line.extended else {
            return nil
        }

        var disks = base.disks
        disks.append(board[line.end])

        self.line = line
        self.disks = disks
    }
}

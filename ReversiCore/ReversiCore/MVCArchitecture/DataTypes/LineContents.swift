public struct LineContents {
    public let line: Line
    public let disks: [Disk?]


    public init(board: Board, line: Line) {
        self.line = line
        // BUG4: Misunderstood that the line.coordinates is sorted as start to end. But it was a Set.
        self.disks = line.coordinates.map { coordinate in board[coordinate] }
    }


    public init?(expandingTo base: LineContents, on board: Board) {
        guard let line = base.line.extended else {
            return nil
        }

        var disks = base.disks
        disks.append(board[line.end])

        self.line = line
        self.disks = disks
    }
}



extension LineContents: Equatable {}

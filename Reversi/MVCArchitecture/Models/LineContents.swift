struct LineContents: Equatable {
    let line: Line
    let disks: [Disk?]


    init(board: Board<Disk?>, line: Line) {
        var disks = [Disk?]()
        var shorterLine: Line? = line

        while let currentLine = shorterLine {
            let diskOrNil = board[currentLine.end]
            disks.insert(diskOrNil, at: 0)
            shorterLine = currentLine.shortened
        }
        // BUG2: Missing addition for start.
        disks.insert(board[line.start], at: 0)

        self.line = line
        self.disks = disks
    }
}

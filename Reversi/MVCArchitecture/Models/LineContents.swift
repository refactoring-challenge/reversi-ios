struct LineContents: Equatable {
    let line: Line
    let contents: [Disk?]


    init(board: Board<Disk?>, line: Line) {
        var contents = [Disk?]()
        var shorterLine: Line? = line

        while let currentLine = shorterLine {
            let diskOrNil = board[currentLine.end]
            contents.insert(diskOrNil, at: 0)
            shorterLine = currentLine.shortened
        }
        // BUG2: Missing addition for start.
        contents.insert(board[line.start], at: 0)

        self.line = line
        self.contents = contents
    }
}

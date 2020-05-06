public struct LineContents {
    public let line: Line
    public let entriesStartToEnd: NonEmptyArray<Entry>
    public var disksStartToEnd: NonEmptyArray<Disk?> {
        self.entriesStartToEnd.map { $0.disk }
    }


    public var count: Int { self.entriesStartToEnd.count }
    public var first: Entry { self.entriesStartToEnd.first }
    public var last: Entry { self.entriesStartToEnd.last }


    public init(line: Line, unsafeEntriesStartToEnd: NonEmptyArray<Entry>) {
        self.line = line
        self.entriesStartToEnd = unsafeEntriesStartToEnd
    }


    public init(board: Board, line: Line) {
        self.init(
            line: line,
            // NOTE: It is safe because it created with the same length of the line and the recent board status.
            // BUG4: Misunderstood that the line.coordinates is sorted as start to end. But it was a Set.
            unsafeEntriesStartToEnd: line.coordinatesStartToEnd.map { coordinate in
                Entry(disk: board[coordinate], at: coordinate)
            }
        )
    }


    public init?(expandingTo base: LineContents, on board: Board) {
        guard let extendedLine = base.line.extended else {
            return nil
        }

        let newEnd = extendedLine.end
        let newEntry = Entry(disk: board[newEnd], at: newEnd)

        // NOTE: It is safe because if the base is also safe. Because it balance between the length of the extended line
        //       and the entries.
        self.init(
            line: extendedLine,
            unsafeEntriesStartToEnd: base.entriesStartToEnd.appended(newEntry)
        )
    }



    public struct Entry {
        public let disk: Disk?
        public let coordinate: Coordinate


        fileprivate init(disk: Disk?, at coordinate: Coordinate) {
            self.disk = disk
            self.coordinate = coordinate
        }
    }
}



extension LineContents: Equatable {}



extension LineContents.Entry: Equatable {}

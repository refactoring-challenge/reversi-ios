public struct FlippableLine {
    public let line: Line
    public let firstEntry: Entry
    public let middleEntries: NonEmptyArray<Entry>
    public let lastEntry: Entry

    public var coordinateToPlace: Coordinate { self.line.end }
    public var coordinatesShouldFlipStartToEnd: NonEmptyArray<Coordinate> { self.middleEntries.map { $0.coordinate } }


    public init(
        line: Line,
        unsafeFirstEntry: Entry,
        unsafeMiddleEntries: NonEmptyArray<Entry>,
        unsafeLastEntry: Entry
    ) {
        self.line = line
        self.firstEntry = unsafeFirstEntry
        self.middleEntries = unsafeMiddleEntries
        self.lastEntry = unsafeLastEntry
    }


    public init?(
        board: Board,
        line: Line,
        turn: Turn
    ) {
        switch FlippableLine.validate(lineContents: board[line], turn: turn) {
        case .unavailable:
            return nil
        case .available(let flippableLine):
            self = flippableLine
        }
    }



    public struct Entry {
        public let coordinate: Coordinate
        public let disk: Disk?


        fileprivate init(from entry: LineContents.Entry) {
            self.disk = entry.disk
            self.coordinate = entry.coordinate
        }


        public init(unsafeDisk disk: Disk?, at coordinate: Coordinate) {
            self.disk = disk
            self.coordinate = coordinate
        }
    }



    public enum ValidationResult {
        case available(FlippableLine)
        case unavailable(because: Reason)



        public enum Reason {
            case startIsNotSameColor
            case endIsNotEmpty
            case lineIsTooShort
            case disksOnLineIncludingEmptyOrSameColor
        }
    }



    public static func validate(lineContents: LineContents, turn: Turn) -> ValidationResult {
        // NOTE: Placable if the line contents satisfies all of the conditions:
        //
        //   1. the start coordinate has the same color as the disk on the board
        //   2. the end coordinate is empty on the board
        //   3. all of disks between the start and the end are have the color of flipped one

        guard lineContents.first.disk == turn.disk else {
            return .unavailable(because: .startIsNotSameColor)
        }

        // BUG3: I expected `x == nil` mean x == .some(.none), but it mean x == .none.
        guard lineContents.last.disk == nil else {
            return .unavailable(because: .endIsNotEmpty)
        }

        guard let betweenStartAndEnd = NonEmptyArray(lineContents.entriesStartToEnd[1..<lineContents.count - 1]) else {
            return .unavailable(because: .lineIsTooShort)
        }

        let flipped = turn.disk.flipped
        let isAvailable = betweenStartAndEnd.allSatisfy { betweenStartAndEnd in betweenStartAndEnd.disk == flipped }

        guard isAvailable else {
            return .unavailable(because: .disksOnLineIncludingEmptyOrSameColor)
        }
        // NOTE: It is safe because the line is validated.
        return .available(FlippableLine(
            line: lineContents.line,
            unsafeFirstEntry: Entry(from: lineContents.first),
            unsafeMiddleEntries: betweenStartAndEnd.map(Entry.init(from:)),
            unsafeLastEntry: Entry(from: lineContents.last)
        ))
    }
}



extension FlippableLine: Hashable {}



extension FlippableLine.Entry: Hashable {}



extension FlippableLine.ValidationResult: Equatable {}

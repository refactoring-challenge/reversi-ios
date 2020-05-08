public struct Board {
    private let array: [[Disk?]]


    public static func initial() -> Board {
        Board(unsafeArray: [
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, .light, .dark, nil, nil, nil],
            [nil, nil, nil, .dark, .light, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
            [nil, nil, nil, nil, nil, nil, nil, nil],
        ])
    }


    public init(unsafeArray: [[Disk?]]) {
        self.array = unsafeArray
    }


    // BUG1: Missing -1 for rawValue (CoordinateX and Y is 1-based)
    public subscript(_ coordinate: Coordinate) -> Disk? {
        // NOTE: all coordinates are bound by 8x8, so it must be success.
        self.array[coordinate.y.rawValue - 1][coordinate.x.rawValue - 1]
    }


    public subscript(_ line: Line) -> LineContents {
        LineContents(board: self, line: line)
    }


    public func forEach(disk block: (Disk?) throws -> Void) rethrows {
        try self.array.forEach {
            try $0.forEach(block)
        }
    }


    public func countDisks() -> DiskCount {
        var light = 0
        var dark = 0

        self.forEach { diskOrNil in
            switch diskOrNil {
            case .none:
                return
            case .some(.dark):
                dark += 1
            case .some(.light):
                light += 1
            }
        }

        return DiskCount(light: light, dark: dark)
    }


    public func gameResult() -> GameResult? {
        let isGameSet = Turn.allCases.allSatisfy { turn in
            self.availableCoordinates(for: turn).isEmpty
        }
        guard isGameSet else {
            return nil
        }

        return self.countDisks().currentGameResult()
    }


    public func unsafeReplaced(with disk: Disk, on line: Line) -> Board {
        var cloneArray = self.array
        line.coordinatesStartToEnd.forEach { coordinate in
            cloneArray[coordinate.y.rawValue - 1][coordinate.x.rawValue - 1] = disk
        }
        return Board(unsafeArray: cloneArray)
    }


    public func availableCoordinates(for turn: Turn) -> Set<Coordinate> {
        Set(self.availableLines(for: turn).map { line in line.coordinateToPlace })
    }


    public func availableLines(for turn: Turn) -> Set<FlippableLine> {
        var result = Set<FlippableLine>()

        for coordinate in Coordinate.allCases {
            guard self[coordinate] == turn.disk else {
                continue
            }
            let coordinateForSameColor = coordinate

            for direction in Direction.allCases {
                // NOTE: Try other directions if the directed distance is out of the board.
                guard let line = Line(
                    start: coordinateForSameColor,
                    directedDistance: DirectedDistance(direction: direction, distance: .two)
                ) else {
                    continue
                }

                var nextLineContents: LineContents? = self[line]
                lineContentsLoop: while let lineContents = nextLineContents {
                    let validationResult = FlippableLine.validate(lineContents: lineContents, turn: turn)
                    switch validationResult {
                    case .unavailable(because: .startIsNotSameColor), .unavailable(because: .lineIsTooShort):
                        // NOTE: .startIsNotSameColor is not reachable because coordinates to search are already filtered.
                        // NOTE: .lineIsTooShort is not reachable because the distances to search start with 2.
                        fatalError("unreachable \(validationResult)\n\(line) \(lineContents)\n\(self.debugDescription)")

                    case .unavailable(because: .endIsNotEmpty):
                        // NOTE: Continue because the longer lines may be available if the end is not empty.
                        //       [L D D  ] --> search order
                        //        ^   ^ ^
                        //        A   B C
                        // A: start
                        // B: not empty
                        // C: available
                        // BUG6: Loop forever because using continue cause unchanged nextLineContents.
                        break

                    case .unavailable(because: .disksOnLineIncludingEmptyOrSameColor):
                        // NOTE: Longer lines cannot be available.
                        // BUG5: Misunderstand that the break without any labels break from lineContentsLoop.
                        break lineContentsLoop

                    case .available(let flippableLine):
                        // BUG7: Wrongly use base lines that have constant distance for all search.
                        result.insert(flippableLine)
                    }

                    nextLineContents = LineContents(expandingTo: lineContents, on: self)
                }
            }
        }

        return result
    }


    // TODO: Serialize/deserialize methods
}



extension Board: Equatable {}



extension Board: CustomDebugStringConvertible {
    public var debugDescription: String {
        let headerX = CoordinateX.allCases.map { $0.debugDescription }.joined()

        let linesY = zip(CoordinateY.allCases, self.array)
            .map {
                let (y, rowX) = $0
                let charsX = rowX.map { $0.description }.joined()
                return "\(y.debugDescription) |\(charsX)| \(y.debugDescription)"
            }
            .joined(separator: "\n")

        return """
                  \(headerX)
                 +--------+
               \(linesY)
                 +--------+
                  \(headerX)
               """
    }
}

struct Board<T> {
    private let array: [[T]]


    init(unsafeArray: [[T]]) {
        self.array = unsafeArray
    }


    // BUG1: Missing -1 for rawValue (CoordinateX and Y is 1-based)
    subscript(_ coordinate: Coordinate) -> T {
        // NOTE: all coordinates are bound by 8x8, so it must be success.
        self.array[coordinate.y.rawValue - 1][coordinate.x.rawValue - 1]
    }


    func updated(value: T, at coordinate: Coordinate) -> Board {
        var cloneArray = self.array
        cloneArray[coordinate.y.rawValue - 1][coordinate.x.rawValue - 1] = value
        return Board(unsafeArray: cloneArray)
    }


    func forEach(_ block: (T) -> Void) {
        self.array.forEach { $0.forEach(block) }
    }


    // TODO: Serialize/deserialize methods
}



extension Board where T == Disk? {
    subscript(_ line: Line) -> LineContents {
        LineContents(board: self, line: line)
    }


    static func initial() -> Board<Disk?> {
        Board<Disk?>(unsafeArray: [
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


    func countDisks() -> DiskCount {
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


    func availableCoordinates(for turn: Turn) -> Set<Coordinate> {
        Set(self.availableLines(for: turn).map { line in line.end })
    }


    func availableLines(for turn: Turn) -> Set<Line> {
        var result = Set<Line>()

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
                while let lineContents = nextLineContents {
                    switch LocationAvailabilityHint.from(lineContents: lineContents, turn: turn) {
                    case .unavailable(because: .startIsNotSameColor), .unavailable(because: .lineIsTooShort):
                        // NOTE: .startIsNotSameColor is not reachable because coordinates to search are already filtered.
                        // NOTE: .lineIsTooShort is not reachable because the distances to search start with 2.
                        fatalError("unreachable \(line) \(lineContents)")

                    case .unavailable(because: .endIsNotEmpty):
                        // NOTE: Continue because the longer lines may be available if the end is not empty.
                        //       [L D D  ] --> search order
                        //        ^   ^ ^
                        //        A   B C
                        // A: start
                        // B: not empty
                        // C: available
                        continue

                    case .unavailable(because: .disksOnLineIncludingEmptyOrSameColor):
                        // NOTE: Longer lines cannot be available.
                        break

                    case .available:
                        result.insert(line)
                    }

                    nextLineContents = LineContents(expandingTo: lineContents, on: self)
                }
            }
        }

        return result
    }
}

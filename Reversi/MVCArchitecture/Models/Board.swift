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


    // TODO: Serialize/deserialize methods
}



extension Board where T == Disk? {
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


    func availableCoordinates(for diskToTest: Disk) -> Set<Line> {
        var result = Set<Line>()

        for coordinate in Coordinate.allCases {
            guard self[coordinate] == diskToTest else {
                continue
            }
            let coordinateForSameColor = coordinate

            for direction in Direction.allCases {
                for distance in Distance.AllCasesLongerThan1ByAscendant {
                    // NOTE: Break if the line is out of the board.
                    guard let line = Line(
                        start: coordinateForSameColor,
                        directedDistance: DirectedDistance(direction: direction, distance: distance)
                    ) else {
                        break
                    }

                    let lineContents = LineContents(board: self, line: line)
                    switch LocationAvailabilityHint.from(lineContents: lineContents, diskToTest: diskToTest) {
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
                }
            }
        }

        return result
    }
}

public struct Line: Hashable {
    public let start: Coordinate
    public let end: Coordinate
    public let directedDistance: DirectedDistance


    public init(start: Coordinate, unsafeEnd: Coordinate, directedDistance: DirectedDistance) {
        self.start = start
        self.end = unsafeEnd
        self.directedDistance = directedDistance
    }


    public init?(start: Coordinate, directedDistance: DirectedDistance) {
        guard let end = start.moved(to: directedDistance) else {
            return nil
        }
        self.start = start
        self.end = end
        self.directedDistance = directedDistance
    }


    public var coordinates: Set<Coordinate> {
        var coordinates = Set<Coordinate>()
        var shorterLine: Line? = self

        while let currentLine = shorterLine {
            coordinates.insert(currentLine.end)
            shorterLine = currentLine.shortened
        }
        // BUG2: Missing addition for start.
        coordinates.insert(self.start)

        return coordinates
    }


    public var shortened: Line? {
        guard let prevDirectedDistance = self.directedDistance.prev else {
            return nil
        }
        return Line(start: start, directedDistance: prevDirectedDistance)
    }


    public var extended: Line? {
        guard let nextDirectedDistance = self.directedDistance.next else {
            return nil
        }
        return Line(start: start, directedDistance: nextDirectedDistance)
    }
}



extension Line: CustomDebugStringConvertible {
    public var debugDescription: String {
        "{Line: start=\(self.start.debugDescription), end=\(self.end.debugDescription), \(self.directedDistance)}"
    }
}

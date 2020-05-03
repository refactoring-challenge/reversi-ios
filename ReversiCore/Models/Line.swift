struct Line: Hashable {
    let start: Coordinate
    let end: Coordinate
    let directedDistance: DirectedDistance


    init(start: Coordinate, unsafeEnd: Coordinate, directedDistance: DirectedDistance) {
        self.start = start
        self.end = unsafeEnd
        self.directedDistance = directedDistance
    }


    init?(start: Coordinate, directedDistance: DirectedDistance) {
        guard let end = start.moved(to: directedDistance) else {
            return nil
        }
        self.start = start
        self.end = end
        self.directedDistance = directedDistance
    }


    var shortened: Line? {
        guard let prevDirectedDistance = self.directedDistance.prev else {
            return nil
        }
        return Line(start: start, directedDistance: prevDirectedDistance)
    }


    var grown: Line? {
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
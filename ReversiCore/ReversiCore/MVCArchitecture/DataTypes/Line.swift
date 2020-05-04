struct Line {
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


    var coordinates: [Coordinate] {
        var coordinates = [Coordinate]()
        var shorterLine: Line? = self

        while let currentLine = shorterLine {
            coordinates.insert(currentLine.end, at: 0)
            shorterLine = currentLine.shortened
        }
        // BUG2: Missing addition for start.
        coordinates.insert(self.start, at: 0)

        return coordinates
    }


    var shortened: Line? {
        guard let prevDirectedDistance = self.directedDistance.shortened else {
            return nil
        }
        return Line(start: start, directedDistance: prevDirectedDistance)
    }


    var extended: Line? {
        guard let nextDirectedDistance = self.directedDistance.extended else {
            return nil
        }
        return Line(start: start, directedDistance: nextDirectedDistance)
    }
}



extension Line: Hashable {}

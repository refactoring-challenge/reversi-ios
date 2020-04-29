struct Line: Hashable {
    let start: Coordinate
    let end: Coordinate
    let direction: Direction
    let distance: Distance


    init(start: Coordinate, unsafeEnd: Coordinate, direction: Direction, distance: Distance) {
        self.start = start
        self.end = unsafeEnd
        self.direction = direction
        self.distance = distance
    }


    init?(start: Coordinate, direction: Direction, distance: Distance) {
        // NOTE: Be nil if the X is out of boards.
        let unsafeX: CoordinateX?
        switch direction {
        case .top, .bottom:
            unsafeX = start.x
        case .left, .topLeft, .bottomLeft:
            unsafeX = CoordinateX(rawValue: start.x.rawValue - distance.rawValue)
        case .right, .topRight, .bottomRight:
            unsafeX = CoordinateX(rawValue: start.x.rawValue + distance.rawValue)
        }

        // NOTE: Be nil if the Y is out of boards.
        let unsafeY: CoordinateY?
        switch direction {
        case .left, .right:
            unsafeY = start.y
        case .top, .topLeft, .topRight:
            unsafeY = CoordinateY(rawValue: start.y.rawValue - distance.rawValue)
        case .bottom, .bottomLeft, .bottomRight:
            unsafeY = CoordinateY(rawValue: start.y.rawValue + distance.rawValue)
        }

        switch (unsafeX, unsafeY) {
        case (.none, _), (_, .none):
            return nil
        case (.some(let x), .some(let y)):
            self.start = start
            self.end = Coordinate(x: x, y: y)
            self.direction = direction
            self.distance = distance
        }
    }


    var shortened: Line? {
        guard let prevDistance = self.distance.prev else {
            return nil
        }
        return Line(start: start, direction: self.direction, distance: prevDistance)
    }
}



extension Line: CustomDebugStringConvertible {
    public var debugDescription: String {
        "{Line: start=\(self.start.debugDescription), end=\(self.end.debugDescription), direction=\(self.direction), distance=\(self.distance)}"
    }
}

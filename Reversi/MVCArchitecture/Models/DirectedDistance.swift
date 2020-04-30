struct DirectedDistance: Hashable {
    let direction: Direction
    let distance: Distance


    var next: DirectedDistance? {
        guard let nextDistance = self.distance.next else {
            return nil
        }
        return DirectedDistance(direction: self.direction, distance: nextDistance)
    }


    var prev: DirectedDistance? {
        guard let prevDistance = self.distance.prev else {
            return nil
        }
        return DirectedDistance(direction: self.direction, distance: prevDistance)
    }
}


extension DirectedDistance: CustomDebugStringConvertible {
    public var debugDescription: String {
        "direction=\(self.direction), distance=\(self.distance)"
    }
}
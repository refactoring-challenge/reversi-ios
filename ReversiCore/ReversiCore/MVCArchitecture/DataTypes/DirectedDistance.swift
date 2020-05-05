public struct DirectedDistance {
    public let direction: Direction
    public let distance: Distance


    public var extended: DirectedDistance? {
        guard let nextDistance = self.distance.next else {
            return nil
        }
        return DirectedDistance(direction: self.direction, distance: nextDistance)
    }


    public var shortened: DirectedDistance? {
        guard let prevDistance = self.distance.prev else {
            return nil
        }
        return DirectedDistance(direction: self.direction, distance: prevDistance)
    }
}



extension DirectedDistance: Hashable {}

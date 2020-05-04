struct DirectedDistance {
    let direction: Direction
    let distance: Distance


    var extended: DirectedDistance? {
        guard let nextDistance = self.distance.next else {
            return nil
        }
        return DirectedDistance(direction: self.direction, distance: nextDistance)
    }


    var shortened: DirectedDistance? {
        guard let prevDistance = self.distance.prev else {
            return nil
        }
        return DirectedDistance(direction: self.direction, distance: prevDistance)
    }
}



extension DirectedDistance: Hashable {}

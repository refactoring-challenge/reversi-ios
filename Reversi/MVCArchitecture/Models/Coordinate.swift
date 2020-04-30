struct Coordinate: Hashable {
    let x: CoordinateX
    let y: CoordinateY


    init(x: CoordinateX, y: CoordinateY) {
        self.x = x
        self.y = y
    }


    func moved(to directedDistance: DirectedDistance) -> Coordinate? {
        // NOTE: Be nil if the X is out of boards.
        let unsafeX: CoordinateX?
        switch directedDistance.direction {
        case .top, .bottom:
            unsafeX = self.x
        case .left, .topLeft, .bottomLeft:
            unsafeX = CoordinateX(rawValue: self.x.rawValue - directedDistance.distance.rawValue)
        case .right, .topRight, .bottomRight:
            unsafeX = CoordinateX(rawValue: self.x.rawValue + directedDistance.distance.rawValue)
        }

        // NOTE: Be nil if the Y is out of boards.
        let unsafeY: CoordinateY?
        switch directedDistance.direction {
        case .left, .right:
            unsafeY = self.y
        case .top, .topLeft, .topRight:
            unsafeY = CoordinateY(rawValue: self.y.rawValue - directedDistance.distance.rawValue)
        case .bottom, .bottomLeft, .bottomRight:
            unsafeY = CoordinateY(rawValue: self.y.rawValue + directedDistance.distance.rawValue)
        }

        switch (unsafeX, unsafeY) {
        case (.none, _), (_, .none):
            return nil
        case (.some(let x), .some(let y)):
            return Coordinate(x: x, y: y)
        }
    }


    static let allCases: [Coordinate] = CoordinateY.allCases.flatMap { y in
        CoordinateX.allCases.map { x in
            Coordinate(x: x, y: y)
        }
    }
}



extension Coordinate: CustomDebugStringConvertible {
    var debugDescription: String {
        "(\(self.x.debugDescription), \(self.y.debugDescription))"
    }
}



enum CoordinateX: Int, CaseIterable, Hashable {
    case one = 1
    case two
    case three
    case four
    case five
    case six
    case seven
    case eight
}



extension CoordinateX: CustomDebugStringConvertible {
    var debugDescription: String {
        "x=\(self.rawValue)"
    }
}



enum CoordinateY: Int, CaseIterable, Hashable {
    case one = 1
    case two
    case three
    case four
    case five
    case six
    case seven
    case eight
}



extension CoordinateY: CustomDebugStringConvertible {
    var debugDescription: String {
        "y=\(self.rawValue)"
    }
}

struct Coordinate: Hashable {
    let x: CoordinateX
    let y: CoordinateY


    init(x: CoordinateX, y: CoordinateY) {
        self.x = x
        self.y = y
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

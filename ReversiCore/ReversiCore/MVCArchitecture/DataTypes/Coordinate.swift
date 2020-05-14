public struct Coordinate {
    public let x: CoordinateX
    public let y: CoordinateY


    public init(x: CoordinateX, y: CoordinateY) {
        self.x = x
        self.y = y
    }


    public func moved(to directedDistance: DirectedDistance) -> Coordinate? {
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


    public static let allCases: [Coordinate] = CoordinateY.allCases.flatMap { y in
        CoordinateX.allCases.map { x in
            Coordinate(x: x, y: y)
        }
    }
}



extension Coordinate: Hashable {}



extension Coordinate: CustomDebugStringConvertible {
    public var debugDescription: String {
        "\(self.x.debugDescription)\(self.y.debugDescription)"
    }
}



extension Coordinate: CustomReflectable {
    public var customMirror: Mirror { Mirror(self, children: []) }
}



public enum CoordinateX: Int, CaseIterable {
    case a = 1
    case b
    case c
    case d
    case e
    case f
    case g
    case h
}



extension CoordinateX: Hashable {}



extension CoordinateX: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .a:
            return "a"
        case .b:
            return "b"
        case .c:
            return "c"
        case .d:
            return "d"
        case .e:
            return "e"
        case .f:
            return "f"
        case .g:
            return "g"
        case .h:
            return "h"
        }
    }
}



public enum CoordinateY: Int, CaseIterable {
    case one = 1
    case two
    case three
    case four
    case five
    case six
    case seven
    case eight
}



extension CoordinateY: Hashable {}



extension CoordinateY: CustomDebugStringConvertible {
    public var debugDescription: String {
        self.rawValue.description
    }
}

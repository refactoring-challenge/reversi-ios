import Foundation

struct BoardConstant {
    static let width: Int = 8
    static let height: Int = 8

    static let xRange: Range<Int> = 0 ..< BoardConstant.width
    static let yRange: Range<Int> = 0 ..< BoardConstant.height

    static var squaresCount: Int { width * height }
}

extension BoardConstant {
    static func convertPositionToIndex(x: Int, y: Int) -> Int? {
        guard xRange.contains(x) && yRange.contains(y) else { return nil }
        return y * width + x
    }
}

import Foundation

public struct BoardConstant {
    public static let width: Int = 8
    public static let height: Int = 8

    public static let xRange: Range<Int> = 0 ..< BoardConstant.width
    public static let yRange: Range<Int> = 0 ..< BoardConstant.height

    public static var squaresCount: Int { width * height }
}

extension BoardConstant {
    public static func convertPositionToIndex(x: Int, y: Int) -> Int? {
        guard xRange.contains(x) && yRange.contains(y) else { return nil }
        return y * width + x
    }
}

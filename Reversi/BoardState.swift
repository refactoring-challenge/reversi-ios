import Foundation

final class BoardState {
    struct Constant {
        let width: Int = 8
        let height: Int = 8

        let xRange: Range<Int>
        let yRange: Range<Int>

        var squaresCount: Int { width * height }

        init() {
            xRange = 0 ..< width
            yRange = 0 ..< height
        }
    }
    class SquareState {
        var disk: Disk?
    }

    let constant: Constant = .init()

    private var squareStates: [SquareState]

    init() {
        squareStates = (0 ..< constant.squaresCount).map { _ in SquareState() }
    }

    func setDisk(_ disk: Disk?, atX x: Int, y: Int) {
        guard let squareState = squareStateAt(x: x, y: y) else {
            preconditionFailure() // FIXME: Add a message.
        }
        squareState.disk = disk
    }

    func reset() {
        for y in constant.yRange {
            for x in constant.xRange {
                setDisk(nil, atX: x, y: y)
            }
        }
        setDisk(.light, atX: constant.width / 2 - 1, y: constant.height / 2 - 1)
        setDisk(.dark, atX: constant.width / 2, y: constant.height / 2 - 1)
        setDisk(.dark, atX: constant.width / 2 - 1, y: constant.height / 2)
        setDisk(.light, atX: constant.width / 2, y: constant.height / 2)
    }

    private func squareStateAt(x: Int, y: Int) -> SquareState? {
        guard constant.xRange.contains(x) && constant.yRange.contains(y) else { return nil }
        return squareStates[y * constant.width + x]
    }

    func diskAt(x: Int, y: Int) -> Disk? {
        squareStateAt(x: x, y: y)?.disk
    }

    func count(of disk: Disk) -> Int {
        var count = 0
        for y in constant.yRange {
            for x in constant.xRange {
                if diskAt(x: x, y: y) == disk {
                    count +=  1
                }
            }
        }
        return count
    }

    func sideWithMoreDisks() -> Disk? {
        let darkCount = count(of: .dark)
        let lightCount = count(of: .light)
        if darkCount == lightCount {
            return nil
        } else {
            return darkCount > lightCount ? .dark : .light
        }
    }
}

extension BoardState.Constant {
    func convertPositionToIndex(x: Int, y: Int) -> Int? {
        guard xRange.contains(x) && yRange.contains(y) else { return nil }
        return y * width + x
    }
}

import Foundation

class BoardState {
    class SquareState {
        var disk: Disk?
    }

    let width: Int = 8
    let height: Int = 8

    let xRange: Range<Int>
    let yRange: Range<Int>

    private var squareStates: [SquareState]

    init() {
        xRange = 0 ..< width
        yRange = 0 ..< height
        squareStates = (0 ..< (width * height)).map { _ in SquareState() }
    }

    func setDisk(_ disk: Disk?, atX x: Int, y: Int) {
        guard let squareState = squareStateAt(x: x, y: y) else {
            preconditionFailure() // FIXME: Add a message.
        }
        squareState.disk = disk
    }

    func reset() {
        for y in yRange {
            for x in xRange {
                setDisk(nil, atX: x, y: y)
            }
        }
        setDisk(.light, atX: width / 2 - 1, y: height / 2 - 1)
        setDisk(.dark, atX: width / 2, y: height / 2 - 1)
        setDisk(.dark, atX: width / 2 - 1, y: height / 2)
        setDisk(.light, atX: width / 2, y: height / 2)
    }

    private func squareStateAt(x: Int, y: Int) -> SquareState? {
        guard xRange.contains(x) && yRange.contains(y) else { return nil }
        return squareStates[y * width + x]
    }

    func diskAt(x: Int, y: Int) -> Disk? {
        squareStateAt(x: x, y: y)?.disk
    }

    func count(of disk: Disk) -> Int {
        var count = 0
        for y in yRange {
            for x in xRange {
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

extension BoardState {
    func convertPositionToIndex(x: Int, y: Int) -> Int? {
        guard xRange.contains(x) && yRange.contains(y) else { return nil }
        return y * width + x
    }
}

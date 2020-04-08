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
    private class SquareState {
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

/* Board logics */
extension BoardState {
    private func canPlaceDisk(_ disk: Disk, atX x: Int, y: Int) -> Bool {
        !flippedDiskCoordinatesByPlacingDisk(disk, atX: x, y: y).isEmpty
    }

    func validMoves(for side: Disk) -> [(x: Int, y: Int)] {
        var coordinates: [(Int, Int)] = []
        for y in constant.yRange {
            for x in constant.xRange {
                if canPlaceDisk(side, atX: x, y: y) {
                    coordinates.append((x, y))
                }
            }
        }
        return coordinates
    }

    func flippedDiskCoordinatesByPlacingDisk(_ disk: Disk, atX x: Int, y: Int) -> [(Int, Int)] {
        let directions = [
            (x: -1, y: -1),
            (x:  0, y: -1),
            (x:  1, y: -1),
            (x:  1, y:  0),
            (x:  1, y:  1),
            (x:  0, y:  1),
            (x: -1, y:  0),
            (x: -1, y:  1),
        ]

        guard diskAt(x: x, y: y) == nil else {
            return []
        }

        var diskCoordinates: [(Int, Int)] = []

        for direction in directions {
            var x = x
            var y = y

            var diskCoordinatesInLine: [(Int, Int)] = []
            flipping: while true {
                x += direction.x
                y += direction.y

                switch (disk, diskAt(x: x, y: y)) { // Uses tuples to make patterns exhaustive
                case (.dark, .some(.dark)), (.light, .some(.light)):
                    diskCoordinates.append(contentsOf: diskCoordinatesInLine)
                    break flipping
                case (.dark, .some(.light)), (.light, .some(.dark)):
                    diskCoordinatesInLine.append((x, y))
                case (_, .none):
                    break flipping
                }
            }
        }

        return diskCoordinates
    }
}

extension BoardState.Constant {
    func convertPositionToIndex(x: Int, y: Int) -> Int? {
        guard xRange.contains(x) && yRange.contains(y) else { return nil }
        return y * width + x
    }
}

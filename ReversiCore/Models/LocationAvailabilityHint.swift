public enum LocationAvailabilityHint: Equatable {
    case available
    case unavailable(because: Reason)


    public enum Reason: Equatable {
        case startIsNotSameColor
        case endIsNotEmpty
        case lineIsTooShort
        case disksOnLineIncludingEmptyOrSameColor
    }


    public static func from(lineContents: LineContents, turn: Turn) -> LocationAvailabilityHint {
        // NOTE: Placable if the line contents satisfies all of the conditions:
        //
        //   1. the start coordinate has the same color as the disk on the board
        //   2. the end coordinate is empty on the board
        //   3. all of disks between the start and the end are have the color of flipped one

        guard lineContents.disks.first == turn.disk else {
            return .unavailable(because: .startIsNotSameColor)
        }

        // BUG3: I expected `x == nil` mean x == .some(.none), but it mean x == .none.
        guard lineContents.disks.last == .some(nil) else {
            return .unavailable(because: .endIsNotEmpty)
        }

        let disksBetweenStartAndEnd = lineContents.disks[1..<lineContents.disks.count-1]
        guard disksBetweenStartAndEnd.count > 0 else {
            return .unavailable(because: .lineIsTooShort)
        }

        let flipped = turn.disk.flipped
        let isAvailable = disksBetweenStartAndEnd.allSatisfy { diskBetweenStartAndEnd in
            diskBetweenStartAndEnd == flipped
        }
        guard isAvailable else {
            return .unavailable(because: .disksOnLineIncludingEmptyOrSameColor)
        }
        return .available
    }
}

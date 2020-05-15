public enum BoardAnimationRequest {
    case shouldAnimate(disk: Disk, at: Coordinate, shouldSyncBefore: Board?)
    case shouldSyncImmediately(board: Board)


    public static func of(animationState: BoardAnimationState) -> BoardAnimationRequest {
        switch animationState {
        case .notAnimating(on: let board):
            return .shouldSyncImmediately(board: board)

        case .placing(at: let coordinate, with: let disk, restLines: _, transaction: let transaction):
            return .shouldAnimate(disk: disk, at: coordinate, shouldSyncBefore: transaction.begin)

        case .flipping(at: let coordinate, with: let disk, restCoordinates: _, restLines: _, transaction: _):
            // BUG17: Should not sync in flipping because both ends of the transaction did not match to transitional boards.
            return .shouldAnimate(disk: disk, at: coordinate, shouldSyncBefore: nil)
        }
    }
}

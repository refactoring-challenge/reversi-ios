public struct BoardAnimationTransaction {
    let begin: Board
    let end: Board


    public init(begin: Board, end: Board) {
        self.begin = begin
        self.end = end
    }


    public static func initial(board: Board) -> BoardAnimationTransaction {
        BoardAnimationTransaction(begin: .empty, end: board)
    }
}



extension BoardAnimationTransaction: Equatable {}

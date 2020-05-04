public protocol GameLife {
    static var turn: Turn { get }
}

public struct Zero: GameLife {
    public static let turn = Turn.first
}
public struct Succ<N: GameLife>: GameLife {
    public static var turn: Turn { N.turn.next }
}

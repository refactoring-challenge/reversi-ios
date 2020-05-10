public protocol GameCommandReceivable: class {
    @discardableResult
    func pass() -> GameCommandResult

    @discardableResult
    func place(at coordinate: Coordinate) -> GameCommandResult

    @discardableResult
    func reset() -> GameCommandResult
}

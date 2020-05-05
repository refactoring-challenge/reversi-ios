public struct NonEmptyArray<T> {
    public let first: T
    public let rest: [T]


    public var last: T {
        guard let last = self.rest.last else {
            return self.first
        }
        return last
    }


    public init<S: Collection>(first: T, rest: S) where S.Element == T {
        self.first = first
        self.rest = Array(rest)
    }


    public init?<S: Collection>(_ array: S) where S.Element == T {
        guard let first = array.first else {
            return nil
        }
        self.init(first: first, rest: array.dropFirst())
    }


    public func randomElement() -> T {
        // NOTE: toArray must return non-empty array, so the randomElement must return an element.
        self.toArray().randomElement()!
    }


    public func map<S>(_ block: (T) throws -> S) rethrows -> NonEmptyArray<S> {
        NonEmptyArray<S>(first: try block(self.first), rest: try self.rest.map(block))
    }


    public func toArray() -> [T] {
        var result = self.rest
        result.insert(self.first, at: 0)
        return result
    }
}
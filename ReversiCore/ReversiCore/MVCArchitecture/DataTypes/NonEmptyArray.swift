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


    public init(first: T) {
        self.init(first: first, rest: [])
    }


    public init?<S: Collection>(_ array: S) where S.Element == T {
        guard let first = array.first else {
            return nil
        }
        self.init(first: first, rest: array.dropFirst())
    }


    public var count: Int { self.rest.count + 1 }


    public subscript(range: Range<Int>) -> ArraySlice<T> {
        self.toArray()[range]
    }


    public func randomElement() -> T {
        // NOTE: toArray must return non-empty array, so the randomElement must return an element.
        self.toArray().randomElement()!
    }


    public func map<S>(_ block: (T) throws -> S) rethrows -> NonEmptyArray<S> {
        NonEmptyArray<S>(first: try block(self.first), rest: try self.rest.map(block))
    }


    public func flatMap<S: Sequence>(_ block: (T) throws -> S) rethrows -> [S.Element] {
        try self.toArray().flatMap(block)
    }


    public func reversed() -> NonEmptyArray<T> {
        // BUG12: Missing first because the code was NonEmptyArray(first: self.last, rest: self.rest.reversed()).
        // NOTE: It is safe because reverse does not change the length.
        NonEmptyArray(self.toArray().reversed())!
    }


    public func forEach(_ block: (T) throws -> Void) rethrows {
        try block(self.first)
        try self.rest.forEach(block)
    }


    public func appended(_ value: T) -> NonEmptyArray<T> {
        var newRest = self.rest
        newRest.append(value)
        return NonEmptyArray(first: self.first, rest: newRest)
    }


    public func dropFirst() -> [T] {
        self.rest
    }


    public func allSatisfy(_ condition: (T) throws -> Bool) rethrows -> Bool {
        guard try condition(self.first) else { return false }
        return try self.rest.allSatisfy(condition)
    }


    public func sorted(by ordering: (T, T) throws -> Bool) rethrows -> NonEmptyArray<T> {
        var newArray = self.toArray()
        try newArray.sort(by: ordering)
        // NOTE: It is safe because sort does not change the length.
        return NonEmptyArray(newArray)!
    }


    public func toArray() -> [T] {
        var result = self.rest
        result.insert(self.first, at: 0)
        return result
    }
}



extension NonEmptyArray: Equatable where T: Equatable {
    public static func ==(lhs: NonEmptyArray<T>, rhs: NonEmptyArray<T>) -> Bool {
        lhs.first == rhs.first && lhs.rest == rhs.rest
    }
}



extension NonEmptyArray: Hashable where T: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.first)
        hasher.combine(self.rest)
    }
}

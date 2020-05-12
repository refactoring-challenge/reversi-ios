public struct Buffer<Element> {
    public var contents = [Element]()
    private let capacity: Int


    public init(capacity: Int) {
        self.capacity = capacity
    }


    public mutating func append(_ newValue: Element) {
        if self.contents.count >= self.capacity {
            self.contents.removeFirst()
        }
        self.contents.append(newValue)
    }


    public var isEmpty: Bool {
        self.contents.isEmpty
    }
}



extension Buffer: Sequence {
    public func makeIterator() -> IndexingIterator<Array<Element>> {
        self.contents.makeIterator()
    }
}
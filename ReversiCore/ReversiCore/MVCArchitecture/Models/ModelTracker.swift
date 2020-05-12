import ReactiveSwift



public protocol ModelTrackerProtocol: class {
    var isEnabled: Bool { get set }
    func printRecentHistory()
}



public class ModelTracker<T>: ModelTrackerProtocol {
    public var isEnabled: Bool
    public private(set) var recentHistory = Buffer<T>(capacity: 100)

    private let stateDidChange: ReactiveSwift.Property<T>
    private let (lifetime, token) = ReactiveSwift.Lifetime.make()


    public init(observing stateDidChange: ReactiveSwift.Property<T>, isEnabled: Bool = false) {
        self.stateDidChange = stateDidChange
        self.isEnabled = isEnabled

        self.stateDidChange
            .producer
            .take(during: self.lifetime)
            .observe(on: QueueScheduler(qos: .userInitiated))
            .on(value: { [weak self] state in
                guard let self = self else { return }
                guard self.isEnabled else { return }
                self.recentHistory.append(state)
            })
            .start()
    }


    public func printRecentHistory() {
        var text = ""
        text.write("===== \(String(reflecting: type(of: T.self))) =====\n")

        if self.recentHistory.isEmpty {
            text.write("No history available (probably the tracker have never been enabled?)\n")
        }
        self.recentHistory.enumerated().forEach {
            let (index, state) = $0
            text.write("[\(index)]\t")
            dump(state, to: &text)
        }
        text.write("\n\n")

        print(text)
    }
}



public class ComposedModelTracker: ModelTrackerProtocol {
    public var isEnabled: Bool {
        didSet(newValue) {
            self.trackers.forEach { tracker in tracker.isEnabled = newValue }
        }
    }
    private let trackers: [ModelTrackerProtocol]


    public init(trackers: [ModelTrackerProtocol], isEnabled: Bool) {
        self.trackers = trackers
        self.isEnabled = isEnabled
    }


    public func printRecentHistory() {
        self.trackers.forEach { tracker in tracker.printRecentHistory() }
    }
}
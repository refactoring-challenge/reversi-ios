import ReactiveSwift



public protocol ModelTrackerProtocol: class {
    var isEnabled: Bool { get set }
}



public class ModelTracker<T>: ModelTrackerProtocol {
    public var isEnabled: Bool
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
                print("ModelTracker<\(String(reflecting: T.self))>:\n\(dumpString(state))")
            })
            .start()
    }
}



public class ComposedModelTracker: ModelTrackerProtocol {
    public var isEnabled: Bool {
        didSet (newValue) {
            self.trackers.forEach { tracker in tracker.isEnabled = newValue }
        }
    }
    private let trackers: [ModelTrackerProtocol]


    public init(trackers: [ModelTrackerProtocol], isEnabled: Bool) {
        self.trackers = trackers
        self.isEnabled = isEnabled
    }
}
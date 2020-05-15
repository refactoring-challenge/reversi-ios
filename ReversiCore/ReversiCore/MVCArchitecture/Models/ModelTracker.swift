import ReactiveSwift



public protocol ModelTrackerProtocol: class {
    var isEnabled: Bool { get set }
    func printRecentHistory()
}



public class ModelTracker<T>: ModelTrackerProtocol {
    public var isEnabled: Bool
    public private(set) var recentHistory = Buffer<T>(capacity: 50)

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
        var text = "===== \(String(reflecting: type(of: T.self))) =====\n"

        if self.recentHistory.isEmpty {
            text.write("No history available (probably the tracker have never been enabled?)\n")
        }
        else {
            self.recentHistory.enumerated().forEach {
                let (index, state) = $0
                text.write("[\(index)]\t")
                dump(state, to: &text)
            }
        }

        print(text)
    }
}

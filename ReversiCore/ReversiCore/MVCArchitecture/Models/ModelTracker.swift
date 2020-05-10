import ReactiveSwift



public class ModelTracker<T> {
    private let stateDidChange: ReactiveSwift.Property<T>
    private let (lifetime, token) = ReactiveSwift.Lifetime.make()


    public init(observing stateDidChange: ReactiveSwift.Property<T>) {
        self.stateDidChange = stateDidChange

        self.stateDidChange
            .producer
            .take(during: self.lifetime)
            .observe(on: QueueScheduler(qos: .userInitiated))
            .on(value: { state in
                print("ModelTracker<\(String(reflecting: T.self))>:\n\(dumpString(state))")
            })
            .start()
    }
}
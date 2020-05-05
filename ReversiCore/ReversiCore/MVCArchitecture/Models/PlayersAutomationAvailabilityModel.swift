import ReactiveSwift



public protocol PlayersAutomationAvailabilityModelProtocol: class {
    var availabilityDidChange: ReactiveSwift.Property<PlayersAutomationAvailability> { get }
    func toggle(for turn: Turn)
}



public class PlayersAutomationAvailabilityModel: PlayersAutomationAvailabilityModelProtocol {
    public let availabilityDidChange: ReactiveSwift.Property<PlayersAutomationAvailability>

    private let stateDidChangeMutable: ReactiveSwift.MutableProperty<PlayersAutomationAvailability>
    private var state: PlayersAutomationAvailability {
        get { self.stateDidChangeMutable.value }
        set { self.stateDidChangeMutable.value = newValue }
    }


    public init(startsWith initialState: PlayersAutomationAvailability) {
        let stateDidChangeMutable = ReactiveSwift.MutableProperty(initialState)
        self.stateDidChangeMutable = stateDidChangeMutable
        self.availabilityDidChange = ReactiveSwift.Property(stateDidChangeMutable)
    }


    public func toggle(for turn: Turn) {
        self.state = self.state.toggled(for: turn)
    }
}
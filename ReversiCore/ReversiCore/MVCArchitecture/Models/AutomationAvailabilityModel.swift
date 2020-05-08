import ReactiveSwift



public protocol AutomationAvailabilityModelProtocol: class {
    var availabilitiesDidChange: ReactiveSwift.Property<AutomationAvailabilities> { get }
    func update(availability: AutomationAvailability, for turn: Turn)
}



public extension AutomationAvailabilityModelProtocol {
    var availabilities: AutomationAvailabilities { self.availabilitiesDidChange.value }
}



public class AutomationAvailabilityModel: AutomationAvailabilityModelProtocol {
    public let availabilitiesDidChange: ReactiveSwift.Property<AutomationAvailabilities>

    private let availabilityDidChangeMutable: ReactiveSwift.MutableProperty<AutomationAvailabilities>
    public private(set) var availability: AutomationAvailabilities {
        get { self.availabilityDidChangeMutable.value }
        set { self.availabilityDidChangeMutable.value = newValue }
    }


    public init(startsWith initialState: AutomationAvailabilities) {
        let stateDidChangeMutable = ReactiveSwift.MutableProperty(initialState)
        self.availabilityDidChangeMutable = stateDidChangeMutable
        self.availabilitiesDidChange = ReactiveSwift.Property(stateDidChangeMutable)
    }


    public func update(availability: AutomationAvailability, for turn: Turn) {
        self.availability = self.availability.updated(availability: availability, for: turn)
    }
}
import ReactiveSwift



public protocol GameAutomatorAvailabilitiesModelProtocol: class {
    var availabilitiesDidChange: ReactiveSwift.Property<GameAutomatorAvailabilities> { get }
    func update(availability: GameAutomatorAvailability, for turn: Turn)
}



public extension GameAutomatorAvailabilitiesModelProtocol {
    var availabilities: GameAutomatorAvailabilities { self.availabilitiesDidChange.value }
}



public class GameAutomatorAvailabilitiesModel: GameAutomatorAvailabilitiesModelProtocol {
    public let availabilitiesDidChange: ReactiveSwift.Property<GameAutomatorAvailabilities>

    private let availabilityDidChangeMutable: ReactiveSwift.MutableProperty<GameAutomatorAvailabilities>
    public private(set) var availability: GameAutomatorAvailabilities {
        get { self.availabilityDidChangeMutable.value }
        set { self.availabilityDidChangeMutable.value = newValue }
    }


    public init(startsWith initialState: GameAutomatorAvailabilities) {
        let stateDidChangeMutable = ReactiveSwift.MutableProperty(initialState)
        self.availabilityDidChangeMutable = stateDidChangeMutable
        self.availabilitiesDidChange = ReactiveSwift.Property(stateDidChangeMutable)
    }


    public func update(availability: GameAutomatorAvailability, for turn: Turn) {
        self.availability = self.availability.updated(availability: availability, for: turn)
    }
}
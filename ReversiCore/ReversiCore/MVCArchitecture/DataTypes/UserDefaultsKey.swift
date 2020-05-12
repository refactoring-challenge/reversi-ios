public struct UserDefaultsKey: RawRepresentable {
    public typealias RawValue = String
    public let rawValue: RawValue


    public init(_ rawValue: RawValue) {
        self.rawValue = rawValue
    }


    public init?(rawValue: RawValue) {
        self.init(rawValue)
    }


    public static let gameStateKey = UserDefaultsKey("REVERSI_GAME_STATE")
    public static let gameAutomatorAvailabilitiesKey = UserDefaultsKey("REVERSI_GAME_AUTOMATOR_AVAILABILITIES")
}

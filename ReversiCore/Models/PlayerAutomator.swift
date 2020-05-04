enum PlayerAutomator {
    // NOTE: Prohibit illegal pass because players cannot pass if one or more available coordinate exist.
    static func select(from availableCoordinates: NonEmptyArray<Coordinate>) -> Coordinate {
        availableCoordinates.randomElement()
    }
}
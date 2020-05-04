enum PlayerAutomator {
    // NOTE: Prohibit illegal pass because players cannot pass if one or more available coordinate exist.
    static let randomSelector: CoordinateSelector = { availableLines in availableLines.randomElement() }
}
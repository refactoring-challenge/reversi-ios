import ReactiveSwift



protocol PlayerAutomationStateModelProtocol {
    var playerAutomationStateDidChange: ReactiveSwift.Property<PlayerAutomationState> { get }
    func toggle()
}



class PlayerAutomationStateModel: PlayerAutomationStateModelProtocol {
    let playerAutomationStateDidChange: ReactiveSwift.Property<PlayerAutomationState>

    private let playerAutomationStateDidChangeMutable: ReactiveSwift.MutableProperty<PlayerAutomationState>
    private var playerAutomationState: PlayerAutomationState {
        get { self.playerAutomationStateDidChangeMutable.value }
        set { self.playerAutomationStateDidChangeMutable.value = newValue }
    }
    private let (lifetime, token) = ReactiveSwift.Lifetime.make()


    init(gameModel: GameModelProtocol, playerAutomationState: PlayerAutomationState) {
        let playerAutomationStateDidChangeMutable = ReactiveSwift.MutableProperty(playerAutomationState)
        self.playerAutomationStateDidChangeMutable = playerAutomationStateDidChangeMutable
        self.playerAutomationStateDidChange = ReactiveSwift.Property(playerAutomationStateDidChangeMutable)


        ReactiveSwift.Property
            .combineLatest(gameModel.gameStateDidChange, self.playerAutomationStateDidChange)
            .signal
            .take(during: self.lifetime)
            .observeValues { [weak gameModel] in
                guard let gameModel = gameModel else { return }

                let (gameState, playerAutomationState) = $0
                switch playerAutomationState {
                case .disabled:
                    // Do nothing.
                    return
                case .enabled:
                    guard let availableCoordinates = NonEmptyArray(gameState.availableCoordinates()) else {
                        gameModel.pass()
                        return
                    }
                    let coordinateSelectedByAutomator = PlayerAutomator.select(from: availableCoordinates)
                    gameModel.placeDisk(at: coordinateSelectedByAutomator)
                }
            }
    }


    func toggle() {
        self.playerAutomationState = self.playerAutomationState.toggled
    }
}
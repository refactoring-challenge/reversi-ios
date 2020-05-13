import Foundation
import ReactiveSwift



public protocol AutoStoredGameModelProtocol: GameModelProtocol {}



public class AutoBackupGameModel: AutoStoredGameModelProtocol {
    private let userDefaultsModel: AnyUserDefaultsModel<GameState, UserDefaultsJSONReadWriterError>
    private let gameModel: GameModelProtocol
    private let (lifetime, token) = ReactiveSwift.Lifetime.make()

    private static let key = UserDefaultsKey.gameStateKey


    public init(userDefaults: UserDefaults, defaultValue: GameState) {
        let userDefaultsModel = UserDefaultsModel<GameState, UserDefaultsJSONReaderError, UserDefaultsJSONWriterError>(
            userDefaults: userDefaults,
            reader: userDefaultsJSONReader(forKey: AutoBackupGameModel.key, defaultValue: defaultValue),
            writer: userDefaultsJSONWriter(forKey: AutoBackupGameModel.key)
        )
        self.userDefaultsModel = userDefaultsModel.asAny()

        let initialGameState: GameState
        switch userDefaultsModel.userDefaultsValue {
        case .failure:
            initialGameState = defaultValue
        case .success(let storedGameState):
            initialGameState = storedGameState
        }
        self.gameModel = GameModel(initialState: .next(by: initialGameState))

        self.start()
    }


    private func start() {
        self.gameModel.gameModelStateDidChange
            .producer
            .take(during: self.lifetime)
            .observe(on: QueueScheduler(qos: .utility))
            .on(value: { [weak self] gameModelState in
                self?.userDefaultsModel.store(value: gameModelState.gameState)
            })
            .start()
    }
}



extension AutoBackupGameModel: GameCommandReceivable {
    public func pass() -> GameCommandResult { self.gameModel.pass() }


    public func place(at coordinate: Coordinate) -> GameCommandResult { self.gameModel.place(at: coordinate) }


    public func reset() -> GameCommandResult { self.gameModel.reset() }
}



extension AutoBackupGameModel: GameModelProtocol {
    public var gameModelStateDidChange: ReactiveSwift.Property<GameModelState> {
        self.gameModel.gameModelStateDidChange
    }

    public var gameCommandDidAccepted: ReactiveSwift.Signal<GameState.AcceptedCommand, Never> {
        self.gameModel.gameCommandDidAccepted
    }
}



extension AutoBackupGameModel: AutomatableGameModelProtocol {
    public var automatableGameStateDidChange: ReactiveSwift.Property<AutomatableGameModelState> {
        self.gameModel.automatableGameStateDidChange
    }
}

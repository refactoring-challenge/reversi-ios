import Foundation
import ReactiveSwift



public protocol AutoBackupGameAutomatorAvailabilitiesModelProtocol: GameAutomatorAvailabilitiesModelProtocol {}



public class AutoBackupGameAutomatorAvailabilitiesModel: AutoBackupGameAutomatorAvailabilitiesModelProtocol {
    private let automatorAvailabilitiesModel: GameAutomatorAvailabilitiesModelProtocol
    private let userDefaultsModel: AnyUserDefaultsModel<GameAutomatorAvailabilities, UserDefaultsJSONReadWriterError>
    private let (lifetime, token) = ReactiveSwift.Lifetime.make()

    private static let key = UserDefaultsKey.gameAutomatorAvailabilitiesKey


    public init(userDefaults: UserDefaults, defaultValue: GameAutomatorAvailabilities) {
        let userDefaultsModel = UserDefaultsModel<GameAutomatorAvailabilities, UserDefaultsJSONReaderError, UserDefaultsJSONWriterError>(
            userDefaults: userDefaults,
            reader: userDefaultsJSONReader(
                forKey: AutoBackupGameAutomatorAvailabilitiesModel.key,
                defaultValue: defaultValue
            ),
            writer: userDefaultsJSONWriter(forKey: AutoBackupGameAutomatorAvailabilitiesModel.key)
        )
        self.userDefaultsModel = userDefaultsModel.asAny()

        self.automatorAvailabilitiesModel = GameAutomatorAvailabilitiesModel(
            startsWith: AutoBackupGameAutomatorAvailabilitiesModel.initialState(
                from: userDefaultsModel.userDefaultsValue,
                defaultValue: defaultValue
            )
        )

        self.start()
    }


    private static func initialState(
        from readResult: Result<GameAutomatorAvailabilities, UserDefaultsJSONReadWriterError>,
        defaultValue: GameAutomatorAvailabilities
    ) -> GameAutomatorAvailabilities {
        switch readResult {
        case .failure:
            return defaultValue
        case .success(let storedState):
            return storedState
        }
    }


    private func start() {
        self.automatorAvailabilitiesModel.availabilitiesDidChange
            .producer
            .take(during: self.lifetime)
            .observe(on: QueueScheduler(qos: .utility))
            .on(value: { [weak self] availabilities in
                self?.userDefaultsModel.store(value: availabilities)
            })
            .start()
    }
}



extension AutoBackupGameAutomatorAvailabilitiesModel: GameAutomatorAvailabilitiesModelProtocol {
    public var availabilitiesDidChange: ReactiveSwift.Property<GameAutomatorAvailabilities> {
        self.automatorAvailabilitiesModel.availabilitiesDidChange
    }


    public func update(availabilities: GameAutomatorAvailabilities) {
        self.automatorAvailabilitiesModel.update(availabilities: availabilities)
    }
}
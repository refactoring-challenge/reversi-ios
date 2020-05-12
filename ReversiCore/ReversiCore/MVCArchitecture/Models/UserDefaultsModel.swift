import Foundation
import ReactiveSwift



public protocol UserDefaultsModelProtocol: class {
    associatedtype Value
    associatedtype Err: Error
    var userDefaultsValueDidChange: ReactiveSwift.Property<Result<Value, Err>> { get }

    func store(value newValue: Value)
}



public extension UserDefaultsModelProtocol {
    var userDefaultsValue: Result<Value, Err> { self.userDefaultsValueDidChange.value }


    func asAny() -> AnyUserDefaultsModel<Value, Err> { AnyUserDefaultsModel(self) }
}



public class UserDefaultsModel<T, ReaderError: Error, WriterError: Error>: UserDefaultsModelProtocol {
    public typealias Err = UserDefaultsReadWriterError<ReaderError, WriterError>
    public typealias State = Result<T, Err>

    public let userDefaultsValueDidChange: ReactiveSwift.Property<State>
    private let userDefaultsDidChangeMutable: ReactiveSwift.MutableProperty<State>

    private let userDefaults: UserDefaults
    private let reader: UserDefaultsReader<T, ReaderError>
    private let writer: UserDefaultsWriter<T, WriterError>


    public init(
        userDefaults: UserDefaults,
        reader: @escaping UserDefaultsReader<T, ReaderError>,
        writer: @escaping UserDefaultsWriter<T, WriterError>
    ) {
        self.userDefaults = userDefaults
        self.reader = reader
        self.writer = writer

        let userDefaultsDidChangeMutable = ReactiveSwift.MutableProperty<State>(
            reader(userDefaults).mapError { .reader($0) })

        self.userDefaultsDidChangeMutable = userDefaultsDidChangeMutable
        self.userDefaultsValueDidChange = ReactiveSwift.Property<State>(userDefaultsDidChangeMutable)
    }


    public func store(value newValue: T) {
        self.userDefaultsDidChangeMutable.value = self.writer(newValue, self.userDefaults)
            .map { newValue }
            .mapError { .writer($0) }
    }
}



public class AnyUserDefaultsModel<T, E: Error>: UserDefaultsModelProtocol {
    public typealias Value = T
    public typealias Err = E

    public var userDefaultsValueDidChange: ReactiveSwift.Property<Result<T, E>> { self._userDefaultsValueDidChange() }
    private let _userDefaultsValueDidChange: () -> ReactiveSwift.Property<Result<T, E>>

    private let _store: (T) -> Void


    public init<M: UserDefaultsModelProtocol>(_ userDefaultsModel: M) where M.Value == T, M.Err == E {
        self._userDefaultsValueDidChange = { userDefaultsModel.userDefaultsValueDidChange }
        self._store = { newValue in userDefaultsModel.store(value: newValue) }
    }


    public func store(value newValue: T) {
        self._store(newValue)
    }
}

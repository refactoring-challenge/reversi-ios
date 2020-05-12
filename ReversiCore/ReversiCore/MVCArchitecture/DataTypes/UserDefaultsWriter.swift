import Foundation



public typealias UserDefaultsWriter<T, E: Error> = (T, UserDefaults) -> Result<Void, E>

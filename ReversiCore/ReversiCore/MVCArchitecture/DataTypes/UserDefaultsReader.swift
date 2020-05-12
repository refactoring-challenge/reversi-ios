import Foundation



public typealias UserDefaultsReader<T, E: Error> = (UserDefaults) -> Result<T, E>

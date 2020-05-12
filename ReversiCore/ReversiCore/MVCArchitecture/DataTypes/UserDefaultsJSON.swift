import Foundation



public func userDefaultsJSONReader<T: Codable>(
    forKey key: UserDefaultsKey,
    defaultValue: T
) -> UserDefaultsReader<T, UserDefaultsJSONReaderError> {
    let decoder = JSONDecoder()
    return { userDefaults -> Result<T, UserDefaultsJSONReaderError> in
        guard let storedData = userDefaults.data(forKey: key.rawValue) else {
            return .success(defaultValue)
        }
        do {
            return .success(try decoder.decode(T.self, from: storedData))
        }
        catch {
            return .failure(.cannotDecode(debugInfo: error))
        }
    }
}



public enum UserDefaultsJSONReaderError: Error {
    case cannotDecode(debugInfo: Any)
}



public func userDefaultsJSONWriter<T: Codable>(
    forKey key: UserDefaultsKey
) -> UserDefaultsWriter<T, UserDefaultsJSONWriterError> {
    let encoder = JSONEncoder()
    return { newValue, userDefaults in
        do {
            let data = try encoder.encode(newValue)
            userDefaults.set(data, forKey: key.rawValue)
            return .success(())
        }
        catch {
            return .failure(.cannotEncode(debugInfo: error))
        }
    }
}



public enum UserDefaultsJSONWriterError: Error {
    case cannotEncode(debugInfo: Any)
}



public typealias UserDefaultsJSONReadWriterError = UserDefaultsReadWriterError<UserDefaultsJSONReaderError, UserDefaultsJSONWriterError>

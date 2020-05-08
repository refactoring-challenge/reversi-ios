import Foundation


public func dumpString<T>(_ value: T) -> String {
    var result = ""
    dump(value, to: &result)
    return result
}
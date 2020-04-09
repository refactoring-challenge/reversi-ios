import Foundation

protocol Repository {
    func saveData(path: String, data: String) throws /* FileIOError */
    func loadData(path: String) throws -> ArraySlice<Substring> /* FileIOError */
}

struct RepositoryImpl: Repository {
    enum FileIOError: Error {
        case write(path: String, cause: Error?)
        case read(path: String, cause: Error?)
    }

    func saveData(path: String, data: String) throws {
        do {
            try data.write(toFile: path, atomically: true, encoding: .utf8)
        } catch let error {
            throw FileIOError.read(path: path, cause: error)
        }
    }

    func loadData(path: String) throws -> ArraySlice<Substring> {
        do {
            let input = try String(contentsOfFile: path, encoding: .utf8)
            return input.split(separator: "\n")[...]
        } catch let error {
            throw FileIOError.write(path: path, cause: error)
        }
    }
}

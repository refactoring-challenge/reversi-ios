public enum UserDefaultsReadWriterError<ReaderError: Error, WriterError: Error>: Error {
    case reader(ReaderError)
    case writer(WriterError)
}

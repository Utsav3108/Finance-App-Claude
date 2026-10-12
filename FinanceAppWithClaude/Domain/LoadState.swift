import Foundation

nonisolated enum LoadState<Value> {
    case idle
    case loading
    case loaded(Value)
    case empty
    case error(UserFacingError)

    var value: Value? {
        if case .loaded(let value) = self { return value }
        return nil
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var error: UserFacingError? {
        if case .error(let error) = self { return error }
        return nil
    }
}

extension LoadState: Equatable where Value: Equatable {}
extension LoadState: Sendable where Value: Sendable {}

/// Text safe to show to a person. Raw `localizedDescription` is never surfaced.
nonisolated struct UserFacingError: Equatable, Sendable, Error {
    var title: String
    var message: String
    var isRetryable: Bool

    init(title: String, message: String, isRetryable: Bool) {
        self.title = title
        self.message = message
        self.isRetryable = isRetryable
    }

    init(_ error: Error) {
        switch error {
        case let e as UserFacingError:
            self = e
        case let e as TransactionServiceError:
            switch e {
            case .loadFailed:
                self.init(title: "Couldn't load data", message: "Something went wrong while loading your transactions. Please try again.", isRetryable: true)
            case .notFound:
                self.init(title: "Transaction not found", message: "This transaction is no longer available.", isRetryable: false)
            case .persistenceFailed:
                self.init(title: "Couldn't save", message: "Your change could not be saved on this device. Please try again.", isRetryable: true)
            case .validation:
                self.init(title: "Check your entry", message: "Some of the details are not valid.", isRetryable: false)
            }
        default:
            self.init(title: "Something went wrong", message: "An unexpected error occurred. Please try again.", isRetryable: true)
        }
    }

    /// Cancellation must be swallowed by callers, never shown.
    static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        if let urlError = error as? URLError, urlError.code == .cancelled { return true }
        return false
    }
}

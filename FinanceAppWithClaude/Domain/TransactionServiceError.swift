import Foundation

nonisolated enum TransactionServiceError: Error, Equatable, Sendable {
    case loadFailed                                  // fixture missing/corrupt, or network failure
    case notFound(String)                            // setReviewed on unknown id
    case persistenceFailed                           // SwiftData save threw
    case validation(TransactionValidationError)      // service-level integrity check
}

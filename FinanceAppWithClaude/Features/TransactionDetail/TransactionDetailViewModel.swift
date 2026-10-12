import Foundation
import Observation

/// Owns the review state of one transaction. Optimistic update with rollback on failure.
@MainActor @Observable
final class TransactionDetailViewModel {
    private(set) var transaction: Transaction
    private(set) var isUpdating = false
    private(set) var error: UserFacingError?
    private let transactionService: any TransactionService

    var isReviewed: Bool { transaction.isReviewed }

    init(transaction: Transaction, transactionService: any TransactionService) {
        self.transaction = transaction
        self.transactionService = transactionService
    }

    /// Sets an explicit review state (idempotent). Returns true when the service confirmed it,
    /// so the caller can notify the lists. A call while one is in flight is ignored.
    @discardableResult
    func setReviewed(_ isReviewed: Bool) async -> Bool {
        guard !isUpdating else { return false }
        let previous = transaction
        transaction.isReviewed = isReviewed
        isUpdating = true
        error = nil
        defer { isUpdating = false }
        do {
            transaction = try await transactionService.setReviewed(isReviewed, forTransactionID: previous.id)
            return true
        } catch {
            transaction = previous
            self.error = UserFacingError(error)
            return false
        }
    }

    /// Flips the current state. Used by the primary button and by Retry (which re-attempts the same target).
    @discardableResult
    func toggleReviewed() async -> Bool {
        await setReviewed(!transaction.isReviewed)
    }

    func dismissError() { error = nil }
}

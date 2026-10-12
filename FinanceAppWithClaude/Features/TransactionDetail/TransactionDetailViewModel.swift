import Foundation
import Observation

/// PLACEHOLDER: replaced by the Transaction detail feature agent.
@MainActor @Observable
final class TransactionDetailViewModel {
    private(set) var transaction: Transaction
    private(set) var isUpdating = false
    private(set) var error: UserFacingError?
    private let transactionService: any TransactionService

    init(transaction: Transaction, transactionService: any TransactionService) {
        self.transaction = transaction
        self.transactionService = transactionService
    }

    /// Optimistic toggle; returns true on success so the caller can notify.
    func setReviewed(_ isReviewed: Bool) async -> Bool {
        let previous = transaction
        transaction.isReviewed = isReviewed
        isUpdating = true
        defer { isUpdating = false }
        do {
            transaction = try await transactionService.setReviewed(isReviewed, forTransactionID: previous.id)
            error = nil
            return true
        } catch {
            transaction = previous
            self.error = UserFacingError(error)
            return false
        }
    }
}

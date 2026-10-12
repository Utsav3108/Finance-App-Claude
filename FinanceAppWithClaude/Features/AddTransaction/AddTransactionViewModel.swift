import Foundation
import Observation

/// PLACEHOLDER: replaced by the Add transaction feature agent.
@MainActor @Observable
final class AddTransactionViewModel {
    var draft = TransactionDraft()
    private(set) var isSubmitting = false
    private(set) var submitError: UserFacingError?
    private(set) var savedTransaction: Transaction?
    private let transactionService: any TransactionService

    init(transactionService: any TransactionService) {
        self.transactionService = transactionService
    }

    var validationErrors: [TransactionValidationError] {
        TransactionValidator.errors(for: draft, now: Date(), locale: .current)
    }

    var canSubmit: Bool { validationErrors.isEmpty && !isSubmitting }

    func submit() async {
        guard case .success(let new) = TransactionValidator.validate(draft, now: Date(), locale: .current),
              !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            savedTransaction = try await transactionService.addTransaction(new)
            submitError = nil
        } catch {
            if UserFacingError.isCancellation(error) { return }
            submitError = UserFacingError(error)
        }
    }
}

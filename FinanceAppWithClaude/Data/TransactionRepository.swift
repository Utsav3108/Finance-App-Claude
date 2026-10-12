import Foundation
import SwiftData

/// Production service: read-only source (fixture or API) + SwiftData overlay for
/// user-added transactions and review state.
nonisolated final class TransactionRepository: TransactionService, BudgetProviding {
    private let source: any TransactionSource
    private let store: LocalStore

    init(source: any TransactionSource, store: LocalStore) {
        self.source = source
        self.store = store
    }

    convenience init(source: any TransactionSource, modelContainer: ModelContainer) {
        self.init(source: source, store: LocalStore(modelContainer: modelContainer))
    }

    func fetchTransactions() async throws -> [Transaction] {
        let base = try await source.loadTransactions()
        do {
            let added = try await store.addedTransactions()
            let overrides = try await store.reviewOverrides()
            return (base + added)
                .map { $0.with(isReviewed: overrides[$0.id] ?? $0.isReviewed) }
                .sorted { $0.date != $1.date ? $0.date > $1.date : $0.id < $1.id }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw TransactionServiceError.persistenceFailed
        }
    }

    func addTransaction(_ draft: NewTransaction) async throws -> Transaction {
        guard !draft.title.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw TransactionServiceError.validation(.titleEmpty)
        }
        guard draft.amount != 0 else {
            throw TransactionServiceError.validation(.amountNotPositive)
        }
        do {
            return try await store.insert(draft)
        } catch {
            throw TransactionServiceError.persistenceFailed
        }
    }

    func setReviewed(_ isReviewed: Bool, forTransactionID id: Transaction.ID) async throws -> Transaction {
        let all = try await fetchTransactions()
        guard let existing = all.first(where: { $0.id == id }) else {
            throw TransactionServiceError.notFound(id)
        }
        do {
            try await store.setReviewed(isReviewed, forTransactionID: id)
        } catch {
            throw TransactionServiceError.persistenceFailed
        }
        return existing.with(isReviewed: isReviewed)
    }

    func fetchBudget() async throws -> Budget {
        try await source.loadBudget()
    }
}

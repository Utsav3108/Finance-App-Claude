import Foundation

nonisolated protocol TransactionService: Sendable {
    /// Full snapshot: transactions merged with local state, newest first.
    func fetchTransactions() async throws -> [Transaction]
    func addTransaction(_ draft: NewTransaction) async throws -> Transaction
    func setReviewed(_ isReviewed: Bool, forTransactionID id: Transaction.ID) async throws -> Transaction
}

/// Read-only budget limits, separate from `TransactionService`.
nonisolated protocol BudgetProviding: Sendable {
    func fetchBudget() async throws -> Budget
}

/// Read-only remote/seed data. `FixtureTransactionSource` implements it; a real API would too.
nonisolated protocol TransactionSource: Sendable {
    func loadTransactions() async throws -> [Transaction]
    func loadBudget() async throws -> Budget
}

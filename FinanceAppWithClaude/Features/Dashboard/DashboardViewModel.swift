import Foundation
import Observation

/// PLACEHOLDER: replaced by the Dashboard feature agent.
@MainActor @Observable
final class DashboardViewModel {
    private(set) var state: LoadState<Int> = .idle
    private let transactionService: any TransactionService
    private let budgetProvider: any BudgetProviding

    init(transactionService: any TransactionService, budgetProvider: any BudgetProviding) {
        self.transactionService = transactionService
        self.budgetProvider = budgetProvider
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            let items = try await transactionService.fetchTransactions()
            state = items.isEmpty ? .empty : .loaded(items.count)
        } catch {
            if UserFacingError.isCancellation(error) { return }
            state = .error(UserFacingError(error))
        }
    }
}

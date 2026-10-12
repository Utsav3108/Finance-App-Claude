import Foundation
import Observation

/// PLACEHOLDER: replaced by the Budget feature agent.
@MainActor @Observable
final class BudgetViewModel {
    private(set) var state: LoadState<[CategorySpending]> = .idle
    private let transactionService: any TransactionService
    private let budgetProvider: any BudgetProviding

    init(transactionService: any TransactionService, budgetProvider: any BudgetProviding) {
        self.transactionService = transactionService
        self.budgetProvider = budgetProvider
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            async let transactions = transactionService.fetchTransactions()
            async let budget = budgetProvider.fetchBudget()
            let spending = BudgetCalculator.spending(for: try await transactions, budget: try await budget)
            state = spending.isEmpty ? .empty : .loaded(spending)
        } catch {
            if UserFacingError.isCancellation(error) { return }
            state = .error(UserFacingError(error))
        }
    }
}

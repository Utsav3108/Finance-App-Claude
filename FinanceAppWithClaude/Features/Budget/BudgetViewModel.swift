import Foundation
import Observation

/// Display data for the Budget screen, derived from one fetched snapshot.
nonisolated struct BudgetContent: Equatable, Sendable {
    var categories: [CategorySpending]
    /// Expenses in the budget period, newest first, keyed for the category detail screen.
    var transactionsByCategory: [TransactionCategory: [Transaction]]
    var period: DateInterval

    var totalSpent: Decimal { BudgetCalculator.totalSpent(categories) }
    /// Sum of configured limits only (categories without a limit contribute nothing).
    var totalBudget: Decimal { BudgetCalculator.totalBudget(categories) }
    var remaining: Decimal { totalBudget - totalSpent }
    var isOverBudget: Bool { totalBudget > 0 && totalSpent > totalBudget }
    var progress: Double? {
        guard totalBudget > 0 else { return nil }
        return NSDecimalNumber(decimal: totalSpent / totalBudget).doubleValue
    }
    var overBudgetCount: Int { categories.filter(\.isOverBudget).count }

    static func make(transactions: [Transaction], budget: Budget) -> BudgetContent {
        let categories = BudgetCalculator.spending(for: transactions, budget: budget)
        let inPeriod = transactions.filter {
            $0.amount < 0 && $0.category != .income && $0.date >= budget.period.start && $0.date < budget.period.end
        }
        return BudgetContent(
            categories: categories,
            transactionsByCategory: Dictionary(grouping: inPeriod, by: \.category)
                .mapValues { $0.sorted { $0.date > $1.date } },
            period: budget.period
        )
    }
}

@MainActor @Observable
final class BudgetViewModel {
    private(set) var state: LoadState<BudgetContent> = .idle
    private let transactionService: any TransactionService
    private let budgetProvider: any BudgetProviding

    init(transactionService: any TransactionService, budgetProvider: any BudgetProviding) {
        self.transactionService = transactionService
        self.budgetProvider = budgetProvider
    }

    func load() async {
        // Keep showing loaded content while refreshing.
        if state.value == nil { state = .loading }
        do {
            async let transactions = transactionService.fetchTransactions()
            async let budget = budgetProvider.fetchBudget()
            let content = BudgetContent.make(transactions: try await transactions, budget: try await budget)
            state = content.categories.isEmpty ? .empty : .loaded(content)
        } catch {
            if UserFacingError.isCancellation(error) { return }
            state = .error(UserFacingError(error))
        }
    }
}

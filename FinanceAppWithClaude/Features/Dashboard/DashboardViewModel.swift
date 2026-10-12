import Foundation
import Observation

/// Everything the Dashboard renders, derived once per load so view bodies stay formatting-free.
struct DashboardContent: Equatable, Sendable {
    var monthLabel: String
    /// Budget remaining (total - spent). Negative when overspent.
    var left: Decimal
    var spent: Decimal
    var total: Decimal
    var topSpending: [CategorySpending]
    var recent: [Transaction]

    var recentRows: [TransactionRowModel] { recent.map(TransactionRowModel.init) }
}

@MainActor @Observable
final class DashboardViewModel {
    nonisolated static let topCategoryCount = 4
    nonisolated static let recentCount = 5

    private(set) var state: LoadState<DashboardContent> = .idle
    /// Transient error from a failed refresh while stale data stays on screen.
    private(set) var refreshError: UserFacingError?

    private let transactionService: any TransactionService
    private let budgetProvider: any BudgetProviding

    init(transactionService: any TransactionService, budgetProvider: any BudgetProviding) {
        self.transactionService = transactionService
        self.budgetProvider = budgetProvider
    }

    /// Initial / data-version load: shows `.loading` only when nothing is on screen yet.
    func load() async {
        if state.value == nil { state = .loading }
        await fetch()
    }

    /// Pull-to-refresh: stale-while-revalidate, never flips back to full-screen loading.
    func refresh() async {
        await fetch()
    }

    func dismissRefreshError() { refreshError = nil }

    private func fetch() async {
        do {
            async let transactions = transactionService.fetchTransactions()
            async let budget = budgetProvider.fetchBudget()
            let (items, plan) = try await (transactions, budget)
            refreshError = nil
            state = items.isEmpty ? .empty : .loaded(Self.makeContent(transactions: items, budget: plan))
        } catch {
            if UserFacingError.isCancellation(error) { return }
            let failure = UserFacingError(error)
            if state.value != nil {
                refreshError = failure
            } else {
                state = .error(failure)
            }
        }
    }

    nonisolated static func makeContent(transactions: [Transaction], budget: Budget,
                                        calendar: Calendar = .current) -> DashboardContent {
        let spending = BudgetCalculator.spending(for: transactions, budget: budget)
        let spent = BudgetCalculator.totalSpent(spending)
        let total = budget.totalLimit
        // Midpoint avoids a UTC period start rendering as the previous month in western time zones.
        let midpoint = budget.period.start.addingTimeInterval(budget.period.duration / 2)
        var monthStyle = Date.FormatStyle().month(.wide)
        monthStyle.calendar = calendar
        monthStyle.timeZone = calendar.timeZone
        return DashboardContent(
            monthLabel: midpoint.formatted(monthStyle),
            left: total - spent,
            spent: spent,
            total: total,
            topSpending: Array(spending.filter { $0.spent > 0 }.prefix(topCategoryCount)),
            recent: Array(transactions.sorted { $0.date > $1.date }.prefix(recentCount))
        )
    }
}

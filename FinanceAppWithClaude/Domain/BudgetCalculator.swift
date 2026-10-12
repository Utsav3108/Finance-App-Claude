import Foundation

nonisolated enum BudgetCalculator {
    /// Per-category spending for `period` (defaults to `budget.period`) against the budget limits.
    /// Only expenses (amount < 0) outside the income category count. Categories with spending or a
    /// limit are returned, largest spend first (ties by name for stable ordering).
    static func spending(
        for transactions: [Transaction],
        budget: Budget,
        period: DateInterval? = nil
    ) -> [CategorySpending] {
        let interval = period ?? budget.period
        var spent: [TransactionCategory: Decimal] = [:]
        var counts: [TransactionCategory: Int] = [:]
        for t in transactions
        where t.amount < 0 && t.category != .income && t.date >= interval.start && t.date < interval.end {
            spent[t.category, default: 0] += -t.amount
            counts[t.category, default: 0] += 1
        }
        let categories = Set(spent.keys).union(budget.limits.keys).subtracting([.income])
        return categories
            .map {
                CategorySpending(
                    category: $0,
                    spent: spent[$0] ?? 0,
                    budget: budget.limits[$0],
                    transactionCount: counts[$0] ?? 0
                )
            }
            .sorted { lhs, rhs in
                lhs.spent != rhs.spent ? lhs.spent > rhs.spent : lhs.category.rawValue < rhs.category.rawValue
            }
    }

    static func totalSpent(_ spending: [CategorySpending]) -> Decimal {
        spending.reduce(0) { $0 + $1.spent }
    }

    static func totalBudget(_ spending: [CategorySpending]) -> Decimal {
        spending.reduce(0) { $0 + ($1.budget ?? 0) }
    }
}

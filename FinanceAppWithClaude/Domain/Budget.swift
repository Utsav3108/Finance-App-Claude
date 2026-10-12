import Foundation

nonisolated struct Budget: Sendable, Equatable {
    var limits: [TransactionCategory: Decimal]
    var period: DateInterval

    var totalLimit: Decimal { limits.values.reduce(0, +) }
}

nonisolated struct CategorySpending: Identifiable, Sendable, Equatable {
    var category: TransactionCategory
    /// Always >= 0 (absolute spending in the period).
    var spent: Decimal
    /// nil = no limit configured.
    var budget: Decimal?
    var transactionCount: Int = 0

    var id: TransactionCategory { category }

    /// spent / budget. Can exceed 1.0 when overspent; views clamp for drawing.
    var progress: Double? {
        guard let budget, budget > 0 else { return nil }
        return NSDecimalNumber(decimal: spent / budget).doubleValue
    }

    /// budget - spent, negative when overspent. nil without a budget.
    var remaining: Decimal? {
        guard let budget else { return nil }
        return budget - spent
    }

    var isOverBudget: Bool {
        guard let remaining else { return false }
        return remaining < 0
    }
}

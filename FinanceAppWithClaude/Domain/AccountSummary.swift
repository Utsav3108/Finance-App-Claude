import Foundation

nonisolated struct AccountSummary: Sendable, Equatable {
    var balance: Decimal
    var spentThisMonth: Decimal      // positive number
    var incomeThisMonth: Decimal     // positive number
    var unreviewedCount: Int
}

nonisolated enum AccountSummaryCalculator {
    /// Summary for the calendar month containing `now`.
    static func make(from transactions: [Transaction], now: Date, calendar: Calendar = .current) -> AccountSummary {
        let interval = calendar.dateInterval(of: .month, for: now) ?? DateInterval(start: now, duration: 0)
        return make(from: transactions, in: interval)
    }

    /// Summary for an explicit period (e.g. `Budget.period`). Balance and unreviewed count cover all transactions.
    static func make(from transactions: [Transaction], in period: DateInterval) -> AccountSummary {
        var spent: Decimal = 0
        var income: Decimal = 0
        for t in transactions where t.date >= period.start && t.date < period.end {
            if t.amount < 0 { spent += -t.amount } else { income += t.amount }
        }
        return AccountSummary(
            balance: transactions.reduce(0) { $0 + $1.amount },
            spentThisMonth: spent,
            incomeThisMonth: income,
            unreviewedCount: transactions.filter { !$0.isReviewed }.count
        )
    }
}

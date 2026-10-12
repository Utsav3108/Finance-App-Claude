import Foundation
@testable import FinanceAppWithClaude

/// Deterministic test data. All dates are fixed UTC instants in October 2026.
nonisolated enum Fixtures {
    static let utc: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    static func date(_ day: Int, month: Int = 10, hour: Int = 12) -> Date {
        utc.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
    }

    static let now = date(12)
    static let enUS = Locale(identifier: "en_US")

    static func transaction(
        id: String = "t-1", title: String = "Coffee", amount: Decimal = -5, day: Int = 5,
        category: TransactionCategory = .dining, isReviewed: Bool = false, source: Transaction.Source = .fixture
    ) -> Transaction {
        Transaction(id: id, title: title, amount: amount, date: date(day), category: category,
                    isReviewed: isReviewed, source: source)
    }

    static let period = DateInterval(start: date(1, hour: 0), end: date(1, month: 11, hour: 0))

    static let budget = Budget(limits: [.dining: 100, .groceries: 200, .transport: 50], period: period)

    static let transactions: [Transaction] = [
        transaction(id: "a", title: "Salary", amount: 3000, day: 1, category: .income, isReviewed: true),
        transaction(id: "b", title: "Cafe", amount: -30, day: 3, category: .dining),
        transaction(id: "c", title: "Restaurant", amount: -90, day: 4, category: .dining),
        transaction(id: "d", title: "Supermarket", amount: -120.50, day: 6, category: .groceries),
        transaction(id: "e", title: "Gadget", amount: -45, day: 7, category: .shopping),
        // Previous month: outside the budget period.
        Transaction(id: "f", title: "Old purchase", amount: -999, date: date(28, month: 9), category: .dining),
    ]

    /// Inline fixture JSON for repository tests.
    static let json = """
    {
      "transactions": [
        {"id": "txn-1", "title": "Groceries Co", "amount": "-50.25", "date": "2026-10-03T12:00:00Z", "category": "groceries"},
        {"id": "txn-2", "title": "Payroll", "amount": 1000, "date": "2026-10-01T12:00:00Z", "category": "income", "isReviewed": true},
        {"id": "txn-3", "title": "Mystery", "amount": "-10", "date": "2026-10-02T12:00:00Z", "category": "spaceships", "note": "unknown category"}
      ],
      "budgets": {
        "period": {"start": "2026-10-01T00:00:00Z", "end": "2026-11-01T00:00:00Z"},
        "limits": {"groceries": "300.00", "dining": "120.50"}
      }
    }
    """.data(using: .utf8)!
}

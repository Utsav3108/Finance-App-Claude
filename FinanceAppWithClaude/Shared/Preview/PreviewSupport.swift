#if DEBUG
import Foundation

/// Sample data for SwiftUI previews. Mock data only.
nonisolated enum PreviewData {
    static let now = Date(timeIntervalSince1970: 1_791_800_000) // 2026-10-12

    private static func day(_ d: Int, hour: Int = 12) -> Date {
        var c = DateComponents()
        c.year = 2026; c.month = 10; c.day = d; c.hour = hour
        c.timeZone = TimeZone(identifier: "UTC")
        return Calendar(identifier: .gregorian).date(from: c) ?? now
    }

    static let transactions: [Transaction] = [
        Transaction(id: "p-1", title: "Whole Foods", amount: -84.32, date: day(11), category: .groceries, note: "Weekly shop", isReviewed: false),
        Transaction(id: "p-2", title: "Monthly Salary", amount: 3200, date: day(10), category: .income, isReviewed: true),
        Transaction(id: "p-3", title: "Sushi Place", amount: -42.80, date: day(9), category: .dining, isReviewed: false),
        Transaction(id: "p-4", title: "Uber", amount: -18.40, date: day(8), category: .transport, isReviewed: true),
        Transaction(id: "p-5", title: "Electric Bill", amount: -72.18, date: day(6), category: .bills, isReviewed: true),
        Transaction(id: "p-6", title: "Cinema Tickets", amount: -28, date: day(5), category: .entertainment, isReviewed: false),
        Transaction(id: "p-7", title: "H&M", amount: -64.99, date: day(3), category: .shopping, isReviewed: false),
        Transaction(id: "p-8", title: "Pharmacy", amount: -23.60, date: day(2), category: .health, isReviewed: true),
    ]

    static let budget = Budget(
        limits: [.groceries: 400, .dining: 250, .transport: 150, .shopping: 300, .bills: 800, .entertainment: 120, .health: 100],
        period: DateInterval(start: day(1, hour: 0), end: day(31, hour: 23))
    )
}

/// In-memory service for previews. `behavior` drives loaded / empty / failing / slow screens.
actor PreviewTransactionService: TransactionService, BudgetProviding {
    nonisolated enum Behavior: Sendable { case loaded, empty, failing, slow }

    private var transactions: [Transaction]
    private let behavior: Behavior

    init(behavior: Behavior = .loaded, transactions: [Transaction] = PreviewData.transactions) {
        self.behavior = behavior
        self.transactions = behavior == .empty ? [] : transactions
    }

    private func gate() async throws {
        switch behavior {
        case .failing: throw TransactionServiceError.loadFailed
        case .slow: try await Task.sleep(for: .seconds(3600))
        default: break
        }
    }

    func fetchTransactions() async throws -> [Transaction] {
        try await gate()
        return transactions.sorted { $0.date > $1.date }
    }

    func addTransaction(_ draft: NewTransaction) async throws -> Transaction {
        try await gate()
        let t = Transaction(id: UUID().uuidString, title: draft.title, amount: draft.amount,
                            currencyCode: draft.currencyCode, date: draft.date, category: draft.category,
                            note: draft.note, isReviewed: false, source: .userAdded)
        transactions.append(t)
        return t
    }

    func setReviewed(_ isReviewed: Bool, forTransactionID id: Transaction.ID) async throws -> Transaction {
        try await gate()
        guard let i = transactions.firstIndex(where: { $0.id == id }) else {
            throw TransactionServiceError.notFound(id)
        }
        transactions[i].isReviewed = isReviewed
        return transactions[i]
    }

    func fetchBudget() async throws -> Budget {
        try await gate()
        return PreviewData.budget
    }
}
#endif

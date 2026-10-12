import Foundation
import Observation

/// Filter applied to the transaction list.
enum TransactionListFilter: String, CaseIterable, Identifiable, Sendable {
    case all, expense, income, unreviewed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All"
        case .expense: "Expenses"
        case .income: "Income"
        case .unreviewed: "Unreviewed"
        }
    }

    var systemImage: String {
        switch self {
        case .all: "list.bullet"
        case .expense: "arrow.up.right"
        case .income: "arrow.down.left"
        case .unreviewed: "exclamationmark.circle"
        }
    }

    func matches(_ t: Transaction) -> Bool {
        switch self {
        case .all: true
        case .expense: t.isExpense
        case .income: t.isIncome
        case .unreviewed: !t.isReviewed
        }
    }
}

/// One day's worth of transactions, newest first.
struct TransactionDaySection: Identifiable, Equatable {
    let id: Date            // start of day
    let title: String
    let transactions: [Transaction]
    let rows: [TransactionRowModel]

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id && lhs.transactions == rhs.transactions }
}

@MainActor @Observable
final class TransactionListViewModel {
    /// Raw load state of all transactions (unfiltered).
    private(set) var state: LoadState<[Transaction]> = .idle

    var searchText = "" { didSet { rebuild() } }
    var filter: TransactionListFilter = .all { didSet { rebuild() } }

    /// Grouped, filtered, sorted sections derived from `state`.
    private(set) var sections: [TransactionDaySection] = []

    private let transactionService: any TransactionService
    private let calendar: Calendar
    private let now: @Sendable () -> Date

    init(
        transactionService: any TransactionService,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.transactionService = transactionService
        self.calendar = calendar
        self.now = now
    }

    var isFiltering: Bool { filter != .all || !trimmedQuery.isEmpty }

    var resultCount: Int { sections.reduce(0) { $0 + $1.transactions.count } }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            let items = try await transactionService.fetchTransactions()
            state = items.isEmpty ? .empty : .loaded(items)
        } catch {
            if UserFacingError.isCancellation(error) { return }
            state = .error(UserFacingError(error))
        }
        rebuild()
    }

    func clearFilters() {
        searchText = ""
        filter = .all
    }

    // MARK: - Derivation

    private var trimmedQuery: String { searchText.trimmingCharacters(in: .whitespacesAndNewlines) }

    private func rebuild() {
        guard let all = state.value else {
            sections = []
            return
        }
        let query = trimmedQuery
        let matching = all.filter { t in
            guard filter.matches(t) else { return false }
            guard !query.isEmpty else { return true }
            return t.title.localizedStandardContains(query)
                || t.category.displayName.localizedStandardContains(query)
        }
        let sorted = matching.sorted {
            $0.date != $1.date ? $0.date > $1.date : $0.id < $1.id
        }
        let grouped = Dictionary(grouping: sorted) { calendar.startOfDay(for: $0.date) }
        sections = grouped.keys.sorted(by: >).map { day in
            let items = grouped[day] ?? []
            return TransactionDaySection(
                id: day, title: title(for: day), transactions: items,
                rows: items.map(TransactionRowModel.init))
        }
    }

    private func title(for day: Date) -> String {
        if calendar.isDate(day, inSameDayAs: now()) { return "Today" }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now()),
           calendar.isDate(day, inSameDayAs: yesterday) { return "Yesterday" }
        var style = Date.FormatStyle(date: .complete, time: .omitted)
        style.calendar = calendar
        style.timeZone = calendar.timeZone
        return day.formatted(style)
    }
}

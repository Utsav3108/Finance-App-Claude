import Foundation
import Synchronization
@testable import FinanceAppWithClaude

/// Configurable, call-recording test double. Thread-safe via `Mutex`.
nonisolated final class MockTransactionService: TransactionService {
    struct State {
        var fetchResult: Result<[Transaction], Error>
        var addResult: Result<Transaction, Error>?
        var setReviewedResult: Result<Transaction, Error>?
        var fetchCount = 0
        var addedDrafts: [NewTransaction] = []
        var reviewedCalls: [(isReviewed: Bool, id: String)] = []
    }

    private let state: Mutex<State>

    init(fetchResult: Result<[Transaction], Error> = .success([])) {
        state = Mutex(State(fetchResult: fetchResult))
    }

    var fetchCount: Int { state.withLock { $0.fetchCount } }
    var addedDrafts: [NewTransaction] { state.withLock { $0.addedDrafts } }
    var reviewedCalls: [(isReviewed: Bool, id: String)] { state.withLock { $0.reviewedCalls } }

    func setFetchResult(_ result: Result<[Transaction], Error>) { state.withLock { $0.fetchResult = result } }
    func setAddResult(_ result: Result<Transaction, Error>?) { state.withLock { $0.addResult = result } }
    func setSetReviewedResult(_ result: Result<Transaction, Error>?) { state.withLock { $0.setReviewedResult = result } }

    func fetchTransactions() async throws -> [Transaction] {
        try state.withLock { s -> [Transaction] in
            s.fetchCount += 1
            return try s.fetchResult.get()
        }
    }

    func addTransaction(_ draft: NewTransaction) async throws -> Transaction {
        try state.withLock { s -> Transaction in
            s.addedDrafts.append(draft)
            if let result = s.addResult { return try result.get() }
            return Transaction(id: "added-\(s.addedDrafts.count)", title: draft.title, amount: draft.amount,
                               currencyCode: draft.currencyCode, date: draft.date, category: draft.category,
                               note: draft.note, isReviewed: false, source: .userAdded)
        }
    }

    func setReviewed(_ isReviewed: Bool, forTransactionID id: Transaction.ID) async throws -> Transaction {
        try state.withLock { s -> Transaction in
            s.reviewedCalls.append((isReviewed, id))
            if let result = s.setReviewedResult { return try result.get() }
            guard let existing = (try? s.fetchResult.get())?.first(where: { $0.id == id }) else {
                throw TransactionServiceError.notFound(id)
            }
            return existing.with(isReviewed: isReviewed)
        }
    }
}

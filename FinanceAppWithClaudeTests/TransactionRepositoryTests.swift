import Foundation
import SwiftData
import Testing
@testable import FinanceAppWithClaude

struct TransactionRepositoryTests {
    private func makeContainer() throws -> ModelContainer {
        try PersistenceSchema.makeContainer(inMemory: true)
    }

    private func makeRepository(
        container: ModelContainer,
        mode: FixtureTransactionSource.Mode = .normal,
        data: Data = Fixtures.json
    ) -> TransactionRepository {
        TransactionRepository(source: FixtureTransactionSource(data: data, mode: mode), modelContainer: container)
    }

    private func newTransaction(title: String = "Lunch", day: Int = 9) -> NewTransaction {
        NewTransaction(title: title, amount: -12.5, currencyCode: "USD", date: Fixtures.date(day),
                       category: .dining, note: "with team")
    }

    @Test func fetchDecodesFixtureAndSortsNewestFirst() async throws {
        let repo = makeRepository(container: try makeContainer())
        let all = try await repo.fetchTransactions()
        #expect(all.map(\.id) == ["txn-1", "txn-3", "txn-2"])
        #expect(all[0].amount == Decimal(string: "-50.25"))
        #expect(all[1].category == .other)                 // unknown category falls back
        #expect(all[2].isReviewed)                         // seed isReviewed
        #expect(all.allSatisfy { $0.source == .fixture })
    }

    @Test func reviewOverrideAppliesToFixtureTransaction() async throws {
        let repo = makeRepository(container: try makeContainer())
        let updated = try await repo.setReviewed(true, forTransactionID: "txn-1")
        #expect(updated.isReviewed)
        let all = try await repo.fetchTransactions()
        #expect(all.first { $0.id == "txn-1" }?.isReviewed == true)

        _ = try await repo.setReviewed(false, forTransactionID: "txn-2")   // override seed true -> false
        let again = try await repo.fetchTransactions()
        #expect(again.first { $0.id == "txn-2" }?.isReviewed == false)
    }

    @Test func addedTransactionAppearsAndCanBeReviewed() async throws {
        let repo = makeRepository(container: try makeContainer())
        let added = try await repo.addTransaction(newTransaction())
        #expect(added.source == .userAdded)
        #expect(!added.id.isEmpty)

        let all = try await repo.fetchTransactions()
        #expect(all.count == 4)
        #expect(all.contains { $0.id == added.id })
        _ = try await repo.setReviewed(true, forTransactionID: added.id)
        let reviewed = try await repo.fetchTransactions().first { $0.id == added.id }
        #expect(reviewed?.isReviewed == true)
        #expect(reviewed?.note == "with team")
    }

    @Test func stateSurvivesRecreatingRepositoryOnSameContainer() async throws {
        let container = try makeContainer()
        let first = makeRepository(container: container)
        let added = try await first.addTransaction(newTransaction())
        _ = try await first.setReviewed(true, forTransactionID: "txn-1")

        let second = makeRepository(container: container)
        let all = try await second.fetchTransactions()
        #expect(all.contains { $0.id == added.id })
        #expect(all.first { $0.id == "txn-1" }?.isReviewed == true)
    }

    @Test func setReviewedUnknownIdThrowsNotFound() async throws {
        let repo = makeRepository(container: try makeContainer())
        await #expect(throws: TransactionServiceError.notFound("nope")) {
            _ = try await repo.setReviewed(true, forTransactionID: "nope")
        }
    }

    @Test func corruptDataMapsToLoadFailed() async throws {
        let repo = makeRepository(container: try makeContainer(), data: Data("not json".utf8))
        await #expect(throws: TransactionServiceError.loadFailed) {
            _ = try await repo.fetchTransactions()
        }
    }

    @Test func forcedErrorAndEmptyModes() async throws {
        let failing = makeRepository(container: try makeContainer(), mode: .forceError)
        await #expect(throws: TransactionServiceError.loadFailed) { _ = try await failing.fetchTransactions() }
        await #expect(throws: TransactionServiceError.loadFailed) { _ = try await failing.fetchBudget() }

        let empty = makeRepository(container: try makeContainer(), mode: .forceEmpty)
        #expect(try await empty.fetchTransactions().isEmpty)
    }

    @Test func budgetIsDecodedFromFixture() async throws {
        let repo = makeRepository(container: try makeContainer())
        let budget = try await repo.fetchBudget()
        #expect(budget.limits[.groceries] == 300)
        #expect(budget.limits[.dining] == Decimal(string: "120.5"))
        #expect(budget.period.start == Fixtures.date(1, hour: 0))
    }

    @Test func bundledFixtureIsValid() async throws {
        let source = FixtureTransactionSource(bundle: Bundle(for: TransactionRepository.self))
        let transactions = try await source.loadTransactions()
        let budget = try await source.loadBudget()
        #expect(transactions.count >= 20)
        #expect(Set(transactions.map(\.category)).count >= 6)
        #expect(Set(transactions.map(\.id)).count == transactions.count)
        #expect(!budget.limits.isEmpty)
    }

    @Test func serviceErrorsMapToUserFacingText() {
        let e = UserFacingError(TransactionServiceError.loadFailed)
        #expect(e.isRetryable)
        #expect(!e.message.isEmpty)
        #expect(UserFacingError(TransactionServiceError.notFound("x")).isRetryable == false)
        #expect(UserFacingError.isCancellation(CancellationError()))
    }

    @Test func mockServiceRecordsCalls() async throws {
        let mock = MockTransactionService(fetchResult: .success(Fixtures.transactions))
        _ = try await mock.fetchTransactions()
        _ = try await mock.addTransaction(newTransaction())
        #expect(mock.fetchCount == 1)
        #expect(mock.addedDrafts.count == 1)
    }
}

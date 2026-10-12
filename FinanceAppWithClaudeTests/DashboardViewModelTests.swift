import Foundation
import Testing
@testable import FinanceAppWithClaude

@MainActor
struct DashboardViewModelTests {
    private func makeVM(
        fetch: Result<[Transaction], Error> = .success(Fixtures.transactions),
        budget: Result<Budget, Error> = .success(Fixtures.budget)
    ) -> (DashboardViewModel, MockTransactionService, MockBudgetProvider) {
        let service = MockTransactionService(fetchResult: fetch)
        let provider = MockBudgetProvider(result: budget)
        return (DashboardViewModel(transactionService: service, budgetProvider: provider), service, provider)
    }

    @Test func successfulLoadDerivesContent() async throws {
        let (vm, _, _) = makeVM()
        await vm.load()
        let content = try #require(vm.state.value)
        // In-period expenses: dining 120 + groceries 120.50 + shopping 45.
        #expect(content.spent == 285.50)
        #expect(content.total == 350)
        #expect(content.left == 64.50)
        #expect(content.topSpending.map(\.category) == [.groceries, .dining, .shopping])
        #expect(content.recent.map(\.id) == ["e", "d", "c", "b", "a"])
    }

    @Test func recentIsNewestFirstAndCapped() async throws {
        let many = (1...9).map { Fixtures.transaction(id: "t\($0)", amount: -1, day: $0) }
        let (vm, _, _) = makeVM(fetch: .success(many))
        await vm.load()
        let content = try #require(vm.state.value)
        #expect(content.recent.map(\.id) == ["t9", "t8", "t7", "t6", "t5"])
    }

    @Test func topCategoriesCapped() async throws {
        let cats: [TransactionCategory] = [.dining, .groceries, .transport, .shopping, .bills, .health]
        let txs = cats.enumerated().map { Fixtures.transaction(id: "c\($0.offset)", amount: -Decimal($0.offset + 1), category: $0.element) }
        let (vm, _, _) = makeVM(fetch: .success(txs))
        await vm.load()
        let content = try #require(vm.state.value)
        #expect(content.topSpending.count == DashboardViewModel.topCategoryCount)
        #expect(content.topSpending.first?.category == .health)
    }

    @Test func serviceFailureProducesErrorState() async {
        let (vm, _, _) = makeVM(fetch: .failure(TransactionServiceError.loadFailed))
        await vm.load()
        #expect(vm.state.error?.isRetryable == true)
        #expect(vm.state.value == nil)
    }

    @Test func budgetFailureProducesErrorState() async {
        let (vm, _, _) = makeVM(budget: .failure(TransactionServiceError.loadFailed))
        await vm.load()
        #expect(vm.state.error != nil)
    }

    @Test func noTransactionsIsEmpty() async {
        let (vm, _, _) = makeVM(fetch: .success([]))
        await vm.load()
        guard case .empty = vm.state else {
            Issue.record("expected .empty, got \(vm.state)")
            return
        }
    }

    @Test func retryAfterFailureRecovers() async {
        let (vm, service, _) = makeVM(fetch: .failure(TransactionServiceError.loadFailed))
        await vm.load()
        service.setFetchResult(.success(Fixtures.transactions))
        await vm.load()
        #expect(vm.state.value != nil)
    }

    @Test func refreshPicksUpNewData() async throws {
        let (vm, service, provider) = makeVM()
        await vm.load()
        service.setFetchResult(.success([Fixtures.transaction(id: "new", amount: -10)]))
        await vm.refresh()
        let content = try #require(vm.state.value)
        #expect(content.recent.map(\.id) == ["new"])
        #expect(service.fetchCount == 2)
        #expect(provider.fetchCount == 2)
        #expect(vm.refreshError == nil)
    }

    @Test func failedRefreshKeepsStaleDataAndSurfacesError() async throws {
        let (vm, service, _) = makeVM()
        await vm.load()
        let before = try #require(vm.state.value)
        service.setFetchResult(.failure(TransactionServiceError.loadFailed))
        await vm.refresh()
        #expect(vm.state.value == before)
        #expect(vm.refreshError != nil)
        service.setFetchResult(.success(Fixtures.transactions))
        await vm.refresh()
        #expect(vm.refreshError == nil)
    }
}

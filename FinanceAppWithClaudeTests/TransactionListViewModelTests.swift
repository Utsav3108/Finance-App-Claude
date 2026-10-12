import Foundation
import Testing
@testable import FinanceAppWithClaude

@MainActor
struct TransactionListViewModelTests {
    private func makeVM(_ result: Result<[Transaction], Error>) -> (TransactionListViewModel, MockTransactionService) {
        let service = MockTransactionService(fetchResult: result)
        let vm = TransactionListViewModel(transactionService: service, calendar: Fixtures.utc, now: { Fixtures.date(7) })
        return (vm, service)
    }

    @Test func loadsSortedNewestFirstAndGroupedByDay() async {
        var items = Fixtures.transactions
        items.append(Fixtures.transaction(id: "g", title: "Late snack", amount: -4, day: 7, category: .dining))
        let (vm, _) = makeVM(.success(items))
        await vm.load()
        #expect(vm.state.value?.count == items.count)
        let ids = vm.sections.map(\.id)
        #expect(ids == ids.sorted(by: >))
        #expect(vm.sections.first?.title == "Today")
        #expect(vm.sections.first?.transactions.map(\.id).sorted() == ["e", "g"])
        #expect(vm.sections.count == 6)
        #expect(vm.sections.dropFirst().first?.title == "Yesterday")
    }

    @Test func errorState() async {
        let (vm, _) = makeVM(.failure(TransactionServiceError.loadFailed))
        await vm.load()
        #expect(vm.state.error != nil)
        #expect(vm.sections.isEmpty)
    }

    @Test func emptyState() async {
        let (vm, _) = makeVM(.success([]))
        await vm.load()
        guard case .empty = vm.state else { Issue.record("expected empty"); return }
    }

    @Test func searchMatchesMerchantAndCategory() async {
        let (vm, _) = makeVM(.success(Fixtures.transactions))
        await vm.load()
        vm.searchText = "cafe"
        #expect(vm.sections.flatMap(\.transactions).map(\.id) == ["b"])
        vm.searchText = "groceries"
        #expect(vm.sections.flatMap(\.transactions).map(\.id) == ["d"])
        vm.searchText = "zzz"
        #expect(vm.sections.isEmpty)
        #expect(vm.isFiltering)
        vm.clearFilters()
        #expect(vm.resultCount == Fixtures.transactions.count)
    }

    @Test func filters() async {
        let (vm, _) = makeVM(.success(Fixtures.transactions))
        await vm.load()
        vm.filter = .income
        #expect(vm.sections.flatMap(\.transactions).map(\.id) == ["a"])
        vm.filter = .expense
        #expect(vm.resultCount == 5)
        vm.filter = .unreviewed
        #expect(vm.sections.flatMap(\.transactions).allSatisfy { !$0.isReviewed })
        vm.filter = .expense
        vm.searchText = "restaurant"
        #expect(vm.resultCount == 1)
    }

    @Test func reloadReappliesFilter() async {
        let (vm, service) = makeVM(.success(Fixtures.transactions))
        await vm.load()
        vm.filter = .income
        service.setFetchResult(.success(Fixtures.transactions + [Fixtures.transaction(id: "z", amount: 10, category: .income)]))
        await vm.load()
        #expect(vm.resultCount == 2)
    }
}

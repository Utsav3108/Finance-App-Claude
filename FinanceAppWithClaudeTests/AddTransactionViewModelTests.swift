import Foundation
import Testing
@testable import FinanceAppWithClaude

@MainActor
struct AddTransactionViewModelTests {
    private func makeVM(_ service: MockTransactionService) -> AddTransactionViewModel {
        AddTransactionViewModel(transactionService: service, now: { Fixtures.now }, locale: Fixtures.enUS)
    }

    private func fill(_ vm: AddTransactionViewModel, title: String = "Coffee", amount: String = "4.50",
                      isExpense: Bool = true, category: TransactionCategory = .dining, note: String = "") {
        vm.draft.title = title
        vm.draft.amountText = amount
        vm.draft.isExpense = isExpense
        vm.draft.category = category
        vm.draft.date = Fixtures.date(10)
        vm.draft.note = note
    }

    @Test func invalidAmountBlocksSubmit() async {
        let service = MockTransactionService()
        let vm = makeVM(service)
        fill(vm, amount: "abc")
        let result = await vm.submit()
        #expect(result == nil)
        #expect(service.addedDrafts.isEmpty)
        #expect(vm.firstInvalidField == .amount)
        #expect(vm.visibleError(for: .amount) != nil)
    }

    @Test func emptyTitleBlocksSubmit() async {
        let service = MockTransactionService()
        let vm = makeVM(service)
        fill(vm, title: "  ")
        #expect(await vm.submit() == nil)
        #expect(service.addedDrafts.isEmpty)
        #expect(vm.firstInvalidField == .title)
    }

    @Test func futureDateBlocksSubmit() async {
        let service = MockTransactionService()
        let vm = makeVM(service)
        fill(vm)
        vm.draft.date = Fixtures.now.addingTimeInterval(86_400)
        #expect(await vm.submit() == nil)
        #expect(service.addedDrafts.isEmpty)
        #expect(vm.firstInvalidField == .date)
    }

    @Test func errorsHiddenUntilTouchedOrAttempted() async {
        let vm = makeVM(MockTransactionService())
        #expect(vm.visibleError(for: .title) == nil)
        vm.touch(.title)
        #expect(vm.visibleError(for: .title) != nil)
        #expect(vm.visibleError(for: .amount) == nil)
        await vm.submit()
        #expect(vm.visibleError(for: .amount) != nil)
    }

    @Test func incomeCategoryOnExpenseIsNormalized() async throws {
        let service = MockTransactionService()
        let vm = makeVM(service)
        fill(vm, category: .income)
        #expect(vm.effectiveCategory == .other)
        #expect(await vm.submit() != nil)
        #expect(service.addedDrafts.first?.category == .other)
    }

    @Test func validExpenseSubmitsOnceWithNegativeAmount() async throws {
        let service = MockTransactionService()
        let vm = makeVM(service)
        fill(vm, title: "  Coffee ", amount: "4.50", note: " latte ")
        let saved = await vm.submit()
        #expect(saved != nil)
        #expect(vm.savedTransaction == saved)
        #expect(service.addedDrafts.count == 1)
        let sent = try #require(service.addedDrafts.first)
        #expect(sent.title == "Coffee")
        #expect(sent.amount == Decimal(string: "-4.5"))
        #expect(sent.category == .dining)
        #expect(sent.note == "latte")
        // Second submit after success is a no-op.
        await vm.submit()
        #expect(service.addedDrafts.count == 1)
    }

    @Test func validIncomeSubmitsPositiveIncomeCategory() async throws {
        let service = MockTransactionService()
        let vm = makeVM(service)
        fill(vm, title: "Salary", amount: "1200", isExpense: false, category: .dining)
        #expect(vm.effectiveCategory == .income)
        await vm.submit()
        let sent = try #require(service.addedDrafts.first)
        #expect(sent.amount == 1200)
        #expect(sent.category == .income)
    }

    @Test func serviceFailureKeepsDraftAndExposesRetryableError() async {
        let service = MockTransactionService()
        service.setAddResult(.failure(TransactionServiceError.persistenceFailed))
        let vm = makeVM(service)
        fill(vm)
        let draftBefore = vm.draft
        #expect(await vm.submit() == nil)
        #expect(vm.draft == draftBefore)
        #expect(vm.savedTransaction == nil)
        #expect(vm.isSubmitting == false)
        #expect(vm.submitError?.isRetryable == true)

        // Retry succeeds and clears the error.
        service.setAddResult(nil)
        #expect(await vm.submit() != nil)
        #expect(vm.submitError == nil)
        #expect(service.addedDrafts.count == 2)
    }

    @Test func editingDraftClearsSubmitError() async {
        let service = MockTransactionService()
        service.setAddResult(.failure(TransactionServiceError.persistenceFailed))
        let vm = makeVM(service)
        fill(vm)
        await vm.submit()
        #expect(vm.submitError != nil)
        vm.draft.title = "Tea"
        #expect(vm.submitError == nil)
    }

    @Test func isSubmittingTogglesAroundServiceCall() async throws {
        let vm = AddTransactionViewModel(transactionService: SlowService(), now: { Fixtures.now }, locale: Fixtures.enUS)
        fill(vm)
        #expect(vm.isSubmitting == false)
        let task = Task { await vm.submit() }
        for _ in 0..<100 where !vm.isSubmitting { try await Task.sleep(for: .milliseconds(5)) }
        #expect(vm.isSubmitting == true)
        // A second submit while in flight is ignored.
        #expect(await vm.submit() == nil)
        let saved = await task.value
        #expect(saved != nil)
        #expect(vm.isSubmitting == false)
    }
}

private struct SlowService: TransactionService {
    func fetchTransactions() async throws -> [Transaction] { [] }
    func addTransaction(_ draft: NewTransaction) async throws -> Transaction {
        try await Task.sleep(for: .milliseconds(200))
        return Transaction(id: "slow", title: draft.title, amount: draft.amount, currencyCode: draft.currencyCode,
                           date: draft.date, category: draft.category, note: draft.note, isReviewed: false, source: .userAdded)
    }
    func setReviewed(_ isReviewed: Bool, forTransactionID id: Transaction.ID) async throws -> Transaction {
        throw TransactionServiceError.notFound(id)
    }
}

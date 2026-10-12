import Foundation
import Testing
@testable import FinanceAppWithClaude

@MainActor
struct BudgetViewModelTests {
    private func makeModel(
        transactions: Result<[Transaction], Error> = .success(Fixtures.transactions),
        budget: Result<Budget, Error> = .success(Fixtures.budget)
    ) -> BudgetViewModel {
        BudgetViewModel(
            transactionService: MockTransactionService(fetchResult: transactions),
            budgetProvider: MockBudgetProvider(result: budget)
        )
    }

    @Test func loadYieldsPerCategorySpendingAndTotals() async {
        let model = makeModel()
        await model.load()
        guard let content = model.state.value else { Issue.record("expected loaded"); return }
        let dining = content.categories.first { $0.category == .dining }
        #expect(dining?.spent == 120)
        #expect(dining?.progress == 1.2)
        let groceries = content.categories.first { $0.category == .groceries }
        #expect(groceries?.spent == Decimal(string: "120.5"))
        #expect(content.totalSpent == Decimal(string: "285.5"))   // 120 + 120.5 + 45
        #expect(content.totalBudget == 350)
        #expect(content.transactionsByCategory[.dining]?.count == 2)
    }

    @Test func overBudgetIsFlagged() async {
        let model = makeModel()
        await model.load()
        let content = model.state.value
        #expect(content?.categories.first { $0.category == .dining }?.isOverBudget == true)
        #expect(content?.categories.first { $0.category == .groceries }?.isOverBudget == false)
        #expect(content?.overBudgetCount == 1)
    }

    @Test func transactionFailureYieldsError() async {
        let model = makeModel(transactions: .failure(TransactionServiceError.loadFailed))
        await model.load()
        #expect(model.state.error?.isRetryable == true)
    }

    @Test func budgetFailureYieldsError() async {
        let model = makeModel(budget: .failure(TransactionServiceError.loadFailed))
        await model.load()
        #expect(model.state.error != nil)
    }

    @Test func noSpendingAndNoLimitsIsEmpty() async {
        let model = makeModel(transactions: .success([]), budget: .success(Budget(limits: [:], period: Fixtures.period)))
        await model.load()
        #expect(model.state == .empty)
    }
}

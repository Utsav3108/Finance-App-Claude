import Foundation
import Testing
@testable import FinanceAppWithClaude

struct BudgetCalculatorTests {
    @Test func totalsPerCategoryAndIgnoresIncomeAndOutOfPeriod() {
        let result = BudgetCalculator.spending(for: Fixtures.transactions, budget: Fixtures.budget)
        let dining = result.first { $0.category == .dining }
        #expect(dining?.spent == 120)            // 30 + 90; September purchase excluded
        #expect(dining?.budget == 100)
        #expect(result.first { $0.category == .groceries }?.spent == Decimal(string: "120.5"))
        #expect(!result.contains { $0.category == .income })
    }

    @Test func overspentProgressExceedsOne() {
        let txs = [Fixtures.transaction(id: "x", amount: -150, day: 3, category: .dining)]
        let dining = BudgetCalculator.spending(for: txs, budget: Fixtures.budget)
            .first { $0.category == .dining }
        #expect(dining?.progress == 1.5)
        #expect(dining?.isOverBudget == true)
        #expect(dining?.remaining == -50)
    }

    @Test func ignoresTransactionsOutsidePeriod() {
        let txs = [
            Fixtures.transaction(id: "in", amount: -20, day: 10, category: .transport),
            Fixtures.transaction(id: "before", amount: -500, day: 30, category: .transport).with(date: Fixtures.date(30, month: 9)),
            Fixtures.transaction(id: "after", amount: -700, day: 2, category: .transport).with(date: Fixtures.date(2, month: 11)),
        ]
        let transport = BudgetCalculator.spending(for: txs, budget: Fixtures.budget).first { $0.category == .transport }
        #expect(transport?.spent == 20)
        #expect(transport?.transactionCount == 1)
    }

    @Test func categoryWithoutBudgetHasNilProgress() {
        let shopping = BudgetCalculator.spending(for: Fixtures.transactions, budget: Fixtures.budget)
            .first { $0.category == .shopping }
        #expect(shopping?.spent == 45)
        #expect(shopping?.budget == nil)
        #expect(shopping?.progress == nil)
        #expect(shopping?.isOverBudget == false)
    }

    @Test func includesBudgetedCategoriesWithNoSpendingAndSortsBySpend() {
        let result = BudgetCalculator.spending(for: Fixtures.transactions, budget: Fixtures.budget)
        let transport = result.first { $0.category == .transport }
        #expect(transport?.spent == 0)
        #expect(result.map(\.spent) == result.map(\.spent).sorted(by: >))
    }

    @Test func accountSummaryUsesPeriod() {
        let summary = AccountSummaryCalculator.make(from: Fixtures.transactions, now: Fixtures.now, calendar: Fixtures.utc)
        #expect(summary.incomeThisMonth == 3000)
        #expect(summary.spentThisMonth == 30 + 90 + Decimal(string: "120.5")! + 45)
        #expect(summary.unreviewedCount == 5)   // everything except Salary
        #expect(summary.balance == 3000 - 30 - 90 - Decimal(string: "120.5")! - 45 - 999)  // balance covers all history
    }
}

private extension Transaction {
    func with(date: Date) -> Transaction {
        var copy = self
        copy.date = date
        return copy
    }
}

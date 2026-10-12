import Foundation
import Testing
@testable import FinanceAppWithClaude

struct TransactionValidatorTests {
    private func draft(title: String = "Coffee", amount: String = "4.50", isExpense: Bool = true,
                       date: Date = Fixtures.date(10)) -> TransactionDraft {
        var d = TransactionDraft()
        d.title = title
        d.amountText = amount
        d.isExpense = isExpense
        d.date = date
        d.category = .dining
        return d
    }

    private func errors(_ d: TransactionDraft) -> [TransactionValidationError] {
        TransactionValidator.errors(for: d, now: Fixtures.now, locale: Fixtures.enUS)
    }

    @Test func validExpenseIsNegative() throws {
        let result = TransactionValidator.validate(draft(title: "  Coffee  ", amount: "4.50"), now: Fixtures.now, locale: Fixtures.enUS)
        let new = try result.get()
        #expect(new.title == "Coffee")
        #expect(new.amount == Decimal(string: "-4.5"))
        #expect(new.category == .dining)
        #expect(new.note == nil)
    }

    @Test func validIncomeIsPositiveAndIncomeCategory() throws {
        let new = try TransactionValidator.validate(draft(amount: "1,200.00", isExpense: false), now: Fixtures.now, locale: Fixtures.enUS).get()
        #expect(new.amount == 1200)
        #expect(new.category == .income)
    }

    @Test func emptyAndTooLongTitle() {
        #expect(errors(draft(title: "   ")) == [.titleEmpty])
        #expect(errors(draft(title: String(repeating: "a", count: 61))) == [.titleTooLong])
    }

    @Test func invalidAmounts() {
        #expect(errors(draft(amount: "abc")) == [.amountInvalid])
        #expect(errors(draft(amount: "")) == [.amountInvalid])
        #expect(errors(draft(amount: "1.234")) == [.amountInvalid])
        #expect(errors(draft(amount: "1.2.3")) == [.amountInvalid])
        #expect(errors(draft(amount: "0")) == [.amountNotPositive])
        #expect(errors(draft(amount: "-5")) == [.amountNotPositive])
        #expect(errors(draft(amount: "1000000.01")) == [.amountTooLarge])
        #expect(errors(draft(amount: "1000000")).isEmpty)
    }

    @Test func futureDateIsRejected() {
        #expect(errors(draft(date: Fixtures.date(13))) == [.dateInFuture])
        #expect(errors(draft(date: Fixtures.now)).isEmpty)
    }

    @Test func multipleErrorsAreReported() {
        let e = errors(draft(title: "", amount: "x", date: Fixtures.date(20)))
        #expect(Set(e) == [.titleEmpty, .amountInvalid, .dateInFuture])
    }

    @Test func localeDecimalSeparator() throws {
        let de = Locale(identifier: "de_DE")
        let new = try TransactionValidator.validate(draft(amount: "12,5"), now: Fixtures.now, locale: de).get()
        #expect(new.amount == Decimal(string: "-12.5"))
    }
}

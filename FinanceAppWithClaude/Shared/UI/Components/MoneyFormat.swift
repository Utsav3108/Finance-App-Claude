import Foundation

/// Currency/date formatting helpers (pure presentation).
enum MoneyFormat {
    /// "$54.20" (unsigned, absolute value).
    static func magnitude(_ amount: Decimal, currencyCode: String) -> String {
        let value = amount < 0 ? -amount : amount
        return value.formatted(.currency(code: currencyCode))
    }

    /// "-$54.20" / "+$3,000.00" via the system currency formatter.
    static func signed(_ amount: Decimal, currencyCode: String) -> String {
        amount.formatted(.currency(code: currencyCode).sign(strategy: .always(showZero: false)))
    }

    /// "$54" for whole amounts, otherwise two decimals.
    static func compact(_ amount: Decimal, currencyCode: String) -> String {
        let value = amount < 0 ? -amount : amount
        let hasFraction = (value as NSDecimalNumber).doubleValue.truncatingRemainder(dividingBy: 1) != 0
        return value.formatted(.currency(code: currencyCode).precision(.fractionLength(hasFraction ? 2 : 0)))
    }

    /// Spoken form: "expense, $54.20" / "income, $3,000.00".
    static func spoken(_ amount: Decimal, currencyCode: String) -> String {
        let kind = amount < 0 ? "expense" : "income"
        return "\(kind), \(magnitude(amount, currencyCode: currencyCode))"
    }

    static func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }
}

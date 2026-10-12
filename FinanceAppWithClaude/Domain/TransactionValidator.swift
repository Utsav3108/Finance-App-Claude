import Foundation

nonisolated enum TransactionValidationError: Hashable, Sendable {
    case titleEmpty, titleTooLong, amountInvalid, amountNotPositive, amountTooLarge, dateInFuture
}

/// Failure payload of `TransactionValidator.validate` (an array is not an `Error`).
nonisolated struct TransactionValidationFailure: Error, Equatable, Sendable {
    var errors: [TransactionValidationError]
}

nonisolated enum TransactionValidator {
    static let maxTitleLength = 60
    static let maxAmount = Decimal(1_000_000)
    static let maxFractionDigits = 2

    static func validate(
        _ draft: TransactionDraft,
        now: Date = Date(),
        locale: Locale = .current
    ) -> Result<NewTransaction, TransactionValidationFailure> {
        var errors: [TransactionValidationError] = []

        let title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if title.isEmpty {
            errors.append(.titleEmpty)
        } else if title.count > maxTitleLength {
            errors.append(.titleTooLong)
        }

        var magnitude: Decimal = 0
        switch parseAmount(draft.amountText, locale: locale) {
        case nil:
            errors.append(.amountInvalid)
        case let value?:
            if value.fractionDigits > maxFractionDigits {
                errors.append(.amountInvalid)
            } else if value <= 0 {
                errors.append(.amountNotPositive)
            } else if value > maxAmount {
                errors.append(.amountTooLarge)
            } else {
                magnitude = value
            }
        }

        if draft.date > now {
            errors.append(.dateInFuture)
        }

        guard errors.isEmpty else { return .failure(TransactionValidationFailure(errors: errors)) }

        let note = draft.note.trimmingCharacters(in: .whitespacesAndNewlines)
        let category: TransactionCategory = draft.isExpense
            ? (draft.category == .income ? .other : draft.category)
            : .income
        return .success(NewTransaction(
            title: title,
            amount: draft.isExpense ? -magnitude : magnitude,
            currencyCode: draft.currencyCode,
            date: draft.date,
            category: category,
            note: note.isEmpty ? nil : note
        ))
    }

    /// Convenience: just the error list (empty when valid).
    static func errors(for draft: TransactionDraft, now: Date = Date(), locale: Locale = .current) -> [TransactionValidationError] {
        if case .failure(let failure) = validate(draft, now: now, locale: locale) { return failure.errors }
        return []
    }

    /// Strict locale-aware parse: digits, one decimal separator, optional grouping and leading sign.
    static func parseAmount(_ text: String, locale: Locale) -> Decimal? {
        var s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }
        let decimalSeparator = locale.decimalSeparator ?? "."
        let grouping = locale.groupingSeparator ?? ","
        if grouping != decimalSeparator { s = s.replacingOccurrences(of: grouping, with: "") }
        s = s.replacingOccurrences(of: " ", with: "")
        var negative = false
        if s.hasPrefix("-") { negative = true; s.removeFirst() }
        guard !s.isEmpty, s.filter({ String($0) == decimalSeparator }).count <= 1 else { return nil }
        let allowed = Set("0123456789" + decimalSeparator)
        guard s.allSatisfy({ allowed.contains($0) }), s.contains(where: \.isNumber) else { return nil }
        let normalized = s.replacingOccurrences(of: decimalSeparator, with: ".")
        guard let value = Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX")) else { return nil }
        return negative ? -value : value
    }
}

private extension Decimal {
    /// Number of digits after the decimal point (0 for integers).
    nonisolated var fractionDigits: Int {
        let text = NSDecimalNumber(decimal: self).stringValue
        guard let dot = text.firstIndex(of: ".") else { return 0 }
        return text.distance(from: dot, to: text.endIndex) - 1
    }
}

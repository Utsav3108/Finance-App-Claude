import Foundation

/// A single money movement. `amount` is signed: negative = spending, positive = income.
nonisolated struct Transaction: Identifiable, Hashable, Sendable, Codable {
    nonisolated enum Source: String, Codable, Sendable {
        case fixture
        case userAdded
    }

    let id: String
    var title: String
    var amount: Decimal
    var currencyCode: String
    var date: Date
    var category: TransactionCategory
    var note: String?
    var isReviewed: Bool
    var source: Source

    var isExpense: Bool { amount < 0 }
    var isIncome: Bool { amount > 0 }

    init(
        id: String,
        title: String,
        amount: Decimal,
        currencyCode: String = "USD",
        date: Date,
        category: TransactionCategory,
        note: String? = nil,
        isReviewed: Bool = false,
        source: Source = .fixture
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.currencyCode = currencyCode
        self.date = date
        self.category = category
        self.note = note
        self.isReviewed = isReviewed
        self.source = source
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, amount, currencyCode, date, category, note, isReviewed, source
    }

    /// Tolerant decoding: amount may be a JSON string or number, optional fields get defaults.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        if let text = try? c.decode(String.self, forKey: .amount) {
            guard let value = Decimal(string: text, locale: Locale(identifier: "en_US_POSIX")) else {
                throw DecodingError.dataCorruptedError(forKey: .amount, in: c, debugDescription: "Invalid amount")
            }
            amount = value
        } else {
            amount = try c.decode(Decimal.self, forKey: .amount)
        }
        currencyCode = try c.decodeIfPresent(String.self, forKey: .currencyCode) ?? "USD"
        date = try c.decode(Date.self, forKey: .date)
        category = try c.decodeIfPresent(TransactionCategory.self, forKey: .category) ?? .other
        note = try c.decodeIfPresent(String.self, forKey: .note)
        isReviewed = try c.decodeIfPresent(Bool.self, forKey: .isReviewed) ?? false
        source = try c.decodeIfPresent(Source.self, forKey: .source) ?? .fixture
    }

    func with(isReviewed: Bool) -> Transaction {
        var copy = self
        copy.isReviewed = isReviewed
        return copy
    }
}

import Foundation

/// Closed set of categories. Unknown raw values decode to `.other` so a server adding a
/// category never breaks decoding. Display name / symbol / colour live in Shared/UI.
nonisolated enum TransactionCategory: String, CaseIterable, Codable, Sendable, Identifiable {
    case groceries, dining, transport, shopping, bills, entertainment, health, income, other

    var id: String { rawValue }

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = TransactionCategory(rawValue: raw) ?? .other
    }

    /// Categories that can carry a spending budget (everything except income).
    static var spendingCategories: [TransactionCategory] {
        allCases.filter { $0 != .income }
    }
}

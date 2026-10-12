import Foundation
import SwiftData

/// User-added transaction. Never leaves `Data/`; `LocalStore` maps to/from `Transaction`.
@Model
nonisolated final class PersistedTransaction {
    @Attribute(.unique) var id: String
    var title: String
    var amount: Decimal
    var currencyCode: String
    var date: Date
    var categoryRaw: String
    var note: String?
    var createdAt: Date

    init(id: String, title: String, amount: Decimal, currencyCode: String, date: Date,
         categoryRaw: String, note: String?, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.amount = amount
        self.currencyCode = currencyCode
        self.date = date
        self.categoryRaw = categoryRaw
        self.note = note
        self.createdAt = createdAt
    }
}

/// Review override keyed by transaction id (applies to fixture and added transactions).
@Model
nonisolated final class ReviewRecord {
    @Attribute(.unique) var transactionID: String
    var isReviewed: Bool
    var updatedAt: Date

    init(transactionID: String, isReviewed: Bool, updatedAt: Date = Date()) {
        self.transactionID = transactionID
        self.isReviewed = isReviewed
        self.updatedAt = updatedAt
    }
}

nonisolated enum PersistenceSchema {
    static let schema = Schema([PersistedTransaction.self, ReviewRecord.self])

    static func makeContainer(inMemory: Bool) throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}

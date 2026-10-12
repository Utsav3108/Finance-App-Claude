import Foundation
import SwiftData

/// Serialized SwiftData access. `@Model` objects never leave this actor.
@ModelActor
actor LocalStore {
    func addedTransactions() throws -> [Transaction] {
        let rows = try modelContext.fetch(FetchDescriptor<PersistedTransaction>())
        return rows.map {
            Transaction(
                id: $0.id,
                title: $0.title,
                amount: $0.amount,
                currencyCode: $0.currencyCode,
                date: $0.date,
                category: TransactionCategory(rawValue: $0.categoryRaw) ?? .other,
                note: $0.note,
                isReviewed: false,
                source: .userAdded
            )
        }
    }

    func reviewOverrides() throws -> [String: Bool] {
        let rows = try modelContext.fetch(FetchDescriptor<ReviewRecord>())
        return Dictionary(rows.map { ($0.transactionID, $0.isReviewed) }, uniquingKeysWith: { _, latest in latest })
    }

    /// Stores a new transaction, assigning a UUID string id.
    func insert(_ new: NewTransaction) throws -> Transaction {
        let id = UUID().uuidString
        modelContext.insert(PersistedTransaction(
            id: id,
            title: new.title,
            amount: new.amount,
            currencyCode: new.currencyCode,
            date: new.date,
            categoryRaw: new.category.rawValue,
            note: new.note
        ))
        try modelContext.save()
        return Transaction(
            id: id, title: new.title, amount: new.amount, currencyCode: new.currencyCode,
            date: new.date, category: new.category, note: new.note, isReviewed: false, source: .userAdded
        )
    }

    /// Upsert by transaction id.
    func setReviewed(_ isReviewed: Bool, forTransactionID id: String) throws {
        var descriptor = FetchDescriptor<ReviewRecord>(predicate: #Predicate { $0.transactionID == id })
        descriptor.fetchLimit = 1
        if let existing = try modelContext.fetch(descriptor).first {
            existing.isReviewed = isReviewed
            existing.updatedAt = Date()
        } else {
            modelContext.insert(ReviewRecord(transactionID: id, isReviewed: isReviewed))
        }
        try modelContext.save()
    }
}

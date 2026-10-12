import Foundation

/// Raw form state bound to the Add screen.
nonisolated struct TransactionDraft: Sendable, Equatable {
    var title = ""
    var amountText = ""
    var isExpense = true
    var category: TransactionCategory = .other
    var date = Date()
    var note = ""
    var currencyCode = "USD"

    init() {}
}

/// Validated, id-less transaction handed to the service. `amount` is signed.
nonisolated struct NewTransaction: Sendable, Equatable {
    var title: String
    var amount: Decimal
    var currencyCode: String
    var date: Date
    var category: TransactionCategory
    var note: String?
}

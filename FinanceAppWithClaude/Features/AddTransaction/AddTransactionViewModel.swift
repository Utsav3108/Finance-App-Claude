import Foundation
import Observation

/// Inputs that can carry a validation message, in on-screen order.
enum AddTransactionField: Hashable, CaseIterable, Sendable {
    case amount, title, date, note
}

/// Owns the Add form state: draft, touched fields, validation, submission.
/// Validation rules live in `TransactionValidator`; this type only decides *when* to show them.
@MainActor @Observable
final class AddTransactionViewModel {
    var draft = TransactionDraft() {
        didSet { if submitError != nil, draft != oldValue { submitError = nil } }
    }
    private(set) var touched: Set<AddTransactionField> = []
    private(set) var hasAttemptedSubmit = false
    private(set) var isSubmitting = false
    private(set) var submitError: UserFacingError?
    private(set) var savedTransaction: Transaction?

    @ObservationIgnored private let transactionService: any TransactionService
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let locale: Locale

    init(transactionService: any TransactionService,
         now: @escaping () -> Date = { Date() },
         locale: Locale = .current) {
        self.transactionService = transactionService
        self.now = now
        self.locale = locale
    }

    // MARK: Derived state

    /// Latest allowed date for the picker.
    var latestDate: Date { now() }

    var validationErrors: [TransactionValidationError] {
        TransactionValidator.errors(for: draft, now: now(), locale: locale)
    }

    var isValid: Bool { validationErrors.isEmpty }

    /// Categories offered for the current transaction type.
    var selectableCategories: [TransactionCategory] { TransactionCategory.spendingCategories }

    /// The category that will actually be saved (income is always `.income`).
    var effectiveCategory: TransactionCategory {
        if !draft.isExpense { return .income }
        return draft.category == .income ? .other : draft.category
    }

    func field(for error: TransactionValidationError) -> AddTransactionField {
        switch error {
        case .titleEmpty, .titleTooLong: .title
        case .amountInvalid, .amountNotPositive, .amountTooLarge: .amount
        case .dateInFuture: .date
        }
    }

    /// First field (in screen order) with an error, regardless of touched state.
    var firstInvalidField: AddTransactionField? {
        let fields = Set(validationErrors.map(field(for:)))
        return AddTransactionField.allCases.first(where: fields.contains)
    }

    /// Message to display for `field`: only after it was touched or a submit was attempted.
    func visibleError(for field: AddTransactionField) -> String? {
        guard hasAttemptedSubmit || touched.contains(field) else { return nil }
        return validationErrors.first(where: { self.field(for: $0) == field }).map(Self.message(for:))
    }

    /// Every message currently visible, for the combined VoiceOver announcement.
    var visibleErrorMessages: [String] {
        AddTransactionField.allCases.compactMap(visibleError(for:))
    }

    static func message(for error: TransactionValidationError) -> String {
        switch error {
        case .titleEmpty: "Enter a merchant or title."
        case .titleTooLong: "Keep the title to \(TransactionValidator.maxTitleLength) characters or fewer."
        case .amountInvalid: "Enter a valid amount with up to 2 decimal places."
        case .amountNotPositive: "Enter an amount greater than zero."
        case .amountTooLarge: "Enter an amount of 1,000,000 or less."
        case .dateInFuture: "Choose today or an earlier date."
        }
    }

    // MARK: Intents

    func touch(_ field: AddTransactionField) { touched.insert(field) }

    /// Validates and, when valid, saves. Returns the saved transaction on success.
    @discardableResult
    func submit() async -> Transaction? {
        guard !isSubmitting, savedTransaction == nil else { return nil }
        hasAttemptedSubmit = true
        submitError = nil

        let new: NewTransaction
        switch TransactionValidator.validate(draft, now: now(), locale: locale) {
        case .failure: return nil
        case .success(let value): new = value
        }

        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let saved = try await transactionService.addTransaction(new)
            savedTransaction = saved
            return saved
        } catch {
            if !UserFacingError.isCancellation(error) { submitError = UserFacingError(error) }
            return nil
        }
    }
}

import Foundation
import Observation

/// PLACEHOLDER: replaced by the Transactions feature agent.
@MainActor @Observable
final class TransactionListViewModel {
    private(set) var state: LoadState<[Transaction]> = .idle
    private let transactionService: any TransactionService

    init(transactionService: any TransactionService) {
        self.transactionService = transactionService
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            let items = try await transactionService.fetchTransactions()
            state = items.isEmpty ? .empty : .loaded(items)
        } catch {
            if UserFacingError.isCancellation(error) { return }
            state = .error(UserFacingError(error))
        }
    }
}

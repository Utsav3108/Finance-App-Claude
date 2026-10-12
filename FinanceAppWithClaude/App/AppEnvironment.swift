import Foundation
import Observation
import SwiftData

/// App-wide dependencies plus a data-change revision counter.
///
/// Screens reload with `.task(id: environment.dataVersion)`; any code that mutates data
/// (add, review) calls `notifyDataChanged()` once the service call succeeded.
@Observable
final class AppEnvironment {
    let transactionService: any TransactionService
    let budgetProvider: any BudgetProviding
    private(set) var dataVersion: Int = 0

    init(transactionService: any TransactionService, budgetProvider: any BudgetProviding) {
        self.transactionService = transactionService
        self.budgetProvider = budgetProvider
    }

    func notifyDataChanged() {
        dataVersion += 1
    }

    /// Production wiring: bundled fixture + SwiftData overlay.
    /// Launch arguments: `-uiTesting` (in-memory store), `-fixtureError`, `-fixtureEmpty`, `-fixtureDelay <ms>`.
    static func live(
        modelContainer: ModelContainer? = nil,
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) -> AppEnvironment {
        let inMemory = arguments.contains("-uiTesting")
        let container: ModelContainer
        do {
            container = try modelContainer ?? PersistenceSchema.makeContainer(inMemory: inMemory)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        #if DEBUG
        let defaultDelay: Duration = .milliseconds(400)
        #else
        let defaultDelay: Duration = .zero
        #endif
        let source = FixtureTransactionSource.fromLaunchArguments(arguments, defaultDelay: defaultDelay)
        let repository = TransactionRepository(source: source, modelContainer: container)
        return AppEnvironment(transactionService: repository, budgetProvider: repository)
    }

    #if DEBUG
    /// Previews: in-memory mock service.
    static func preview(
        behavior: PreviewTransactionService.Behavior = .loaded,
        transactions: [Transaction] = PreviewData.transactions
    ) -> AppEnvironment {
        let service = PreviewTransactionService(behavior: behavior, transactions: transactions)
        return AppEnvironment(transactionService: service, budgetProvider: service)
    }

    /// Previews with explicit doubles (e.g. test mocks or custom services).
    static func preview(
        transactionService: any TransactionService,
        budgetProvider: any BudgetProviding
    ) -> AppEnvironment {
        AppEnvironment(transactionService: transactionService, budgetProvider: budgetProvider)
    }
    #endif
}

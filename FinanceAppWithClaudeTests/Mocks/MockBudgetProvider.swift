import Foundation
import Synchronization
@testable import FinanceAppWithClaude

nonisolated final class MockBudgetProvider: BudgetProviding {
    private let result: Mutex<Result<Budget, Error>>
    private let calls = Mutex(0)

    init(result: Result<Budget, Error> = .success(Fixtures.budget)) {
        self.result = Mutex(result)
    }

    var fetchCount: Int { calls.withLock { $0 } }
    func setResult(_ new: Result<Budget, Error>) { result.withLock { $0 = new } }

    func fetchBudget() async throws -> Budget {
        calls.withLock { $0 += 1 }
        return try result.withLock { try $0.get() }
    }
}

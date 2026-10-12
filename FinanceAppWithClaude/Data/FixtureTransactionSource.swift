import Foundation

/// Reads `transactions.json` from the bundle (stands in for the remote API).
///
/// Launch arguments: `-fixtureError` makes every load throw `.loadFailed`,
/// `-fixtureEmpty` returns no transactions. `-fixtureDelay <ms>` overrides the latency.
nonisolated struct FixtureTransactionSource: TransactionSource {
    nonisolated enum Mode: Sendable, Equatable {
        case normal, forceError, forceEmpty
    }

    private let dataProvider: @Sendable () throws -> Data
    let delay: Duration
    let mode: Mode

    /// Inline JSON (tests, previews).
    init(data: Data, delay: Duration = .zero, mode: Mode = .normal) {
        self.dataProvider = { data }
        self.delay = delay
        self.mode = mode
    }

    /// Bundle resource.
    init(bundle: Bundle = .main, resource: String = "transactions", delay: Duration = .zero, mode: Mode = .normal) {
        self.dataProvider = {
            guard let url = bundle.url(forResource: resource, withExtension: "json") else {
                throw TransactionServiceError.loadFailed
            }
            return try Data(contentsOf: url)
        }
        self.delay = delay
        self.mode = mode
    }

    /// Builds a bundle source configured from launch arguments.
    static func fromLaunchArguments(
        _ arguments: [String] = ProcessInfo.processInfo.arguments,
        defaultDelay: Duration = .zero,
        bundle: Bundle = .main
    ) -> FixtureTransactionSource {
        var delay = defaultDelay
        if let i = arguments.firstIndex(of: "-fixtureDelay"), arguments.indices.contains(i + 1),
           let ms = Int(arguments[i + 1]) {
            delay = .milliseconds(ms)
        }
        let mode: Mode = arguments.contains("-fixtureError") ? .forceError
            : arguments.contains("-fixtureEmpty") ? .forceEmpty : .normal
        return FixtureTransactionSource(bundle: bundle, delay: delay, mode: mode)
    }

    func loadTransactions() async throws -> [Transaction] {
        try await simulateLatency()
        switch mode {
        case .forceError: throw TransactionServiceError.loadFailed
        case .forceEmpty: return []
        case .normal: return try decode().transactions
        }
    }

    func loadBudget() async throws -> Budget {
        try await simulateLatency()
        if mode == .forceError { throw TransactionServiceError.loadFailed }
        return try decode().budget
    }

    private func simulateLatency() async throws {
        if delay > .zero { try await Task.sleep(for: delay) }
    }

    private func decode() throws -> (transactions: [Transaction], budget: Budget) {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let file = try decoder.decode(FixtureFile.self, from: try dataProvider())
            var limits: [TransactionCategory: Decimal] = [:]
            for (key, text) in file.budgets.limits {
                guard let value = Decimal(string: text, locale: Locale(identifier: "en_US_POSIX")) else {
                    throw TransactionServiceError.loadFailed
                }
                limits[TransactionCategory(rawValue: key) ?? .other] = value
            }
            let period = DateInterval(start: file.budgets.period.start, end: file.budgets.period.end)
            return (file.transactions, Budget(limits: limits, period: period))
        } catch {
            throw TransactionServiceError.loadFailed
        }
    }
}

private nonisolated struct FixtureFile: Decodable {
    struct Period: Decodable { let start: Date; let end: Date }
    struct Budgets: Decodable { let period: Period; let limits: [String: String] }
    let transactions: [Transaction]
    let budgets: Budgets
}

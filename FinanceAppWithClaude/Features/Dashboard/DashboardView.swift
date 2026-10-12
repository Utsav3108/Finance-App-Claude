import SwiftUI

/// PLACEHOLDER: replaced by the Dashboard feature agent.
struct DashboardView: View {
    let transactionService: any TransactionService
    let budgetProvider: any BudgetProviding
    let onSelectTransaction: (Transaction) -> Void
    let onSeeAllTransactions: () -> Void
    let onSeeBudget: () -> Void

    @Environment(AppEnvironment.self) private var environment
    @State private var viewModel: DashboardViewModel

    init(
        transactionService: any TransactionService,
        budgetProvider: any BudgetProviding,
        onSelectTransaction: @escaping (Transaction) -> Void,
        onSeeAllTransactions: @escaping () -> Void,
        onSeeBudget: @escaping () -> Void
    ) {
        self.transactionService = transactionService
        self.budgetProvider = budgetProvider
        self.onSelectTransaction = onSelectTransaction
        self.onSeeAllTransactions = onSeeAllTransactions
        self.onSeeBudget = onSeeBudget
        _viewModel = State(initialValue: DashboardViewModel(transactionService: transactionService, budgetProvider: budgetProvider))
    }

    var body: some View {
        StateContainer(
            state: viewModel.state,
            empty: EmptyStateConfig(title: "No activity yet", message: "Add a transaction to get started."),
            retry: { Task { await viewModel.load() } }
        ) { count in
            VStack(spacing: AppSpacing.md) {
                Text("Dashboard placeholder: \(count) transactions")
                    .font(AppFont.rowTitle)
                PillButton(title: "See all transactions", action: onSeeAllTransactions)
                PillButton(title: "See budget", action: onSeeBudget)
            }
        }
        .navigationTitle("Dashboard")
        .task(id: environment.dataVersion) { await viewModel.load() }
    }
}

#if DEBUG
#Preview {
    let env = AppEnvironment.preview()
    NavigationStack {
        DashboardView(transactionService: env.transactionService, budgetProvider: env.budgetProvider,
                      onSelectTransaction: { _ in }, onSeeAllTransactions: {}, onSeeBudget: {})
    }
    .environment(env)
}
#endif

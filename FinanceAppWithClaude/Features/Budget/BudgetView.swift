import SwiftUI

/// PLACEHOLDER: replaced by the Budget feature agent.
struct BudgetView: View {
    let transactionService: any TransactionService
    let budgetProvider: any BudgetProviding

    @Environment(AppEnvironment.self) private var environment
    @State private var viewModel: BudgetViewModel

    init(transactionService: any TransactionService, budgetProvider: any BudgetProviding) {
        self.transactionService = transactionService
        self.budgetProvider = budgetProvider
        _viewModel = State(initialValue: BudgetViewModel(transactionService: transactionService, budgetProvider: budgetProvider))
    }

    var body: some View {
        StateContainer(
            state: viewModel.state,
            empty: EmptyStateConfig(title: "No spending yet", message: "Spending by category will appear here."),
            retry: { Task { await viewModel.load() } }
        ) { items in
            ScrollView {
                LazyVStack(spacing: AppSpacing.md) {
                    ForEach(items) { BudgetCategoryRow(spending: $0) }
                }
                .padding(AppSpacing.lg)
            }
        }
        .navigationTitle("Budget")
        .task(id: environment.dataVersion) { await viewModel.load() }
    }
}

#if DEBUG
#Preview {
    let env = AppEnvironment.preview()
    NavigationStack {
        BudgetView(transactionService: env.transactionService, budgetProvider: env.budgetProvider)
    }
    .environment(env)
}
#endif

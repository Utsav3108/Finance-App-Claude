import SwiftUI

/// Owns navigation: tabs, one NavigationStack per tab, the Add sheet and data-change fan-out.
struct RootView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var selectedTab: AppTab = .dashboard
    @State private var dashboardPath: [Route] = []
    @State private var transactionsPath: [Route] = []
    @State private var budgetPath: [Route] = []
    @State private var isPresentingAdd = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Dashboard", systemImage: "house", value: AppTab.dashboard) {
                NavigationStack(path: $dashboardPath) {
                    DashboardView(
                        transactionService: environment.transactionService,
                        budgetProvider: environment.budgetProvider,
                        onSelectTransaction: { dashboardPath.append(.transaction($0)) },
                        onSeeAllTransactions: { selectedTab = .transactions },
                        onSeeBudget: { selectedTab = .budget }
                    )
                    .addButtonInset { isPresentingAdd = true }
                    .navigationDestination(for: Route.self) { destination(for: $0) }
                }
            }
            Tab("Transactions", systemImage: "list.bullet", value: AppTab.transactions) {
                NavigationStack(path: $transactionsPath) {
                    TransactionListView(
                        transactionService: environment.transactionService,
                        onSelectTransaction: { transactionsPath.append(.transaction($0)) },
                        onAdd: { isPresentingAdd = true }
                    )
                    .addButtonInset { isPresentingAdd = true }
                    .navigationDestination(for: Route.self) { destination(for: $0) }
                }
            }
            Tab("Budget", systemImage: "chart.pie", value: AppTab.budget) {
                NavigationStack(path: $budgetPath) {
                    BudgetView(
                        transactionService: environment.transactionService,
                        budgetProvider: environment.budgetProvider
                    )
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            NavIconButton(systemImage: "plus", label: "Add transaction") { isPresentingAdd = true }
                        }
                    }
                    .navigationDestination(for: Route.self) { destination(for: $0) }
                }
            }
        }
        .tint(AppColor.accentBrand)
        .sheet(isPresented: $isPresentingAdd) {
            NavigationStack {
                AddTransactionView(
                    transactionService: environment.transactionService,
                    onSaved: { _ in
                        isPresentingAdd = false
                        environment.notifyDataChanged()
                    },
                    onCancel: { isPresentingAdd = false }
                )
            }
            .presentationDetents([.large])
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .transaction(let transaction):
            TransactionDetailView(
                transaction: transaction,
                transactionService: environment.transactionService,
                onChanged: { environment.notifyDataChanged() }
            )
        }
    }
}

private extension View {
    /// Floating add button in a bottom safe-area inset so scroll content clears it.
    func addButtonInset(action: @escaping () -> Void) -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack {
                Spacer(minLength: 0)
                FloatingAddButton(action: action)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xs)
        }
    }
}

#if DEBUG
#Preview {
    RootView().environment(AppEnvironment.preview())
}
#endif

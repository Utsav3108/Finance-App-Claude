import SwiftUI

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
            retry: { Task { await viewModel.load() } },
            placeholder: { DashboardPlaceholder() }
        ) { content in
            DashboardContentView(
                content: content,
                refreshError: viewModel.refreshError,
                onSelectTransaction: onSelectTransaction,
                onSeeAllTransactions: onSeeAllTransactions,
                onSeeBudget: onSeeBudget
            )
        }
        .background(AppColor.surface)
        .refreshable { await viewModel.refresh() }
        .navigationTitle("Dashboard")
        .task(id: environment.dataVersion) { await viewModel.load() }
    }
}

private struct DashboardContentView: View {
    let content: DashboardContent
    let refreshError: UserFacingError?
    let onSelectTransaction: (Transaction) -> Void
    let onSeeAllTransactions: () -> Void
    let onSeeBudget: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                if let refreshError {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "exclamationmark.triangle.fill").accessibilityHidden(true)
                        Text("\(refreshError.title). Showing saved data.")
                    }
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.expense)
                    .accessibilityElement(children: .combine)
                }

                BalanceCard(
                    title: "Left",
                    amount: content.left,
                    spent: content.spent,
                    total: content.total,
                    monthLabel: content.monthLabel,
                    onAdjust: onSeeBudget
                )

                if !content.topSpending.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        SectionHeader(title: "Spending summary", actionTitle: "See budget",
                                      actionAccessibilityLabel: "See budget", action: onSeeBudget)
                        ForEach(content.topSpending) { spending in
                            BudgetCategoryRow(spending: spending, style: .compact)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    SectionHeader(title: "Recent transactions", actionTitle: "See all",
                                  actionAccessibilityLabel: "See all recent transactions", action: onSeeAllTransactions)
                    ForEach(content.recent) { transaction in
                        Button { onSelectTransaction(transaction) } label: {
                            TransactionRow(model: TransactionRowModel(transaction))
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Opens details")
                    }
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
        }
    }
}

/// Redacted skeleton shown while the first load is in flight.
private struct DashboardPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            BalanceCard(title: "Left", amount: 0, spent: 0, total: 0, monthLabel: "Month")
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                SectionHeader(title: "Recent transactions")
                ForEach(0..<3, id: \.self) { _ in
                    TransactionRow(model: .placeholder)
                }
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .frame(maxHeight: .infinity, alignment: .top)
        .redacted(reason: .placeholder)
        .allowsHitTesting(false)
    }
}

#if DEBUG
private struct DashboardPreviewHost: View {
    let behavior: PreviewTransactionService.Behavior
    var body: some View {
        let env = AppEnvironment.preview(behavior: behavior)
        NavigationStack {
            DashboardView(transactionService: env.transactionService, budgetProvider: env.budgetProvider,
                          onSelectTransaction: { _ in }, onSeeAllTransactions: {}, onSeeBudget: {})
        }
        .environment(env)
    }
}

#Preview("Loaded") { DashboardPreviewHost(behavior: .loaded) }
#Preview("Empty") { DashboardPreviewHost(behavior: .empty) }
#Preview("Failing") { DashboardPreviewHost(behavior: .failing) }
#Preview("Slow") { DashboardPreviewHost(behavior: .slow) }
#Preview("AX5") { DashboardPreviewHost(behavior: .loaded).dynamicTypeSize(.accessibility5) }
#endif

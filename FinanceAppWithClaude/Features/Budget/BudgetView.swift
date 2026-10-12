import SwiftUI

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
            empty: EmptyStateConfig(title: "No budget yet", message: "Spending and limits by category will appear here."),
            retry: { Task { await viewModel.load() } }
        ) { content in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AppSpacing.md) {
                    BudgetSummaryCard(content: content)
                    ForEach(content.categories) { spending in
                        NavigationLink {
                            BudgetCategoryDetailView(
                                spending: spending,
                                transactions: content.transactionsByCategory[spending.category] ?? []
                            )
                        } label: {
                            BudgetCategoryRow(spending: spending)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Shows transactions")
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
            }
        }
        .background(AppColor.surface)
        .refreshable { await viewModel.load() }
        .navigationTitle("Budget")
        .task(id: environment.dataVersion) { await viewModel.load() }
    }
}

// MARK: - Summary

private struct BudgetSummaryCard: View {
    let content: BudgetContent
    var currencyCode: String = "USD"

    private var monthLabel: String {
        content.period.start.formatted(.dateTime.month(.wide).year())
    }

    private var tint: Color { content.isOverBudget ? AppColor.expense : AppColor.accentBrand }

    private var accessibilityText: String {
        let spent = MoneyFormat.magnitude(content.totalSpent, currencyCode: currencyCode)
        guard content.totalBudget > 0 else { return "\(monthLabel), \(spent) spent, no budget set" }
        let total = MoneyFormat.magnitude(content.totalBudget, currencyCode: currencyCode)
        let percent = Int(((content.progress ?? 0) * 100).rounded())
        let tail = content.isOverBudget
            ? "over budget by \(MoneyFormat.magnitude(content.remaining, currencyCode: currencyCode))"
            : "\(MoneyFormat.magnitude(content.remaining, currencyCode: currencyCode)) left"
        var text = "\(monthLabel), \(spent) of \(total) spent, \(percent) percent, \(tail)"
        if content.overBudgetCount > 0 {
            text += ", \(content.overBudgetCount) \(content.overBudgetCount == 1 ? "category" : "categories") over budget"
        }
        return text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(monthLabel)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.textTertiaryAccessible)
            Text(MoneyFormat.magnitude(content.totalSpent, currencyCode: currencyCode))
                .font(AppFont.amountHero)
                .monospacedDigit()
                .foregroundStyle(AppColor.textPrimary)
                .minimumScaleFactor(0.7)
            if content.totalBudget > 0 {
                Text("spent of \(MoneyFormat.magnitude(content.totalBudget, currencyCode: currencyCode))")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textTertiaryAccessible)
                if let progress = content.progress {
                    ProgressBar(fraction: progress, tint: tint, height: .large)
                }
                HStack(spacing: AppSpacing.xs) {
                    if content.isOverBudget {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(AppColor.expense)
                    }
                    Text(content.isOverBudget
                         ? "\(MoneyFormat.magnitude(content.remaining, currencyCode: currencyCode)) over budget"
                         : "\(MoneyFormat.magnitude(content.remaining, currencyCode: currencyCode)) left")
                        .font(AppFont.rowTitle)
                        .foregroundStyle(content.isOverBudget ? AppColor.expense : AppColor.textPrimary)
                }
            } else {
                Text("spent, no budget set")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textTertiaryAccessible)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.lg)
        .background(AppColor.fillSecondary, in: RoundedRectangle(cornerRadius: AppRadius.card))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }
}

// MARK: - Category detail (local push)

private struct BudgetCategoryDetailView: View {
    let spending: CategorySpending
    let transactions: [Transaction]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.md) {
                BudgetCategoryRow(spending: spending)
                if transactions.isEmpty {
                    Text("No transactions this period.")
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textTertiaryAccessible)
                } else {
                    ForEach(transactions) { transaction in
                        TransactionRow(model: TransactionRowModel(transaction))
                    }
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
        }
        .background(AppColor.surface)
        .navigationTitle(spending.category.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
private struct BudgetPreviewHost: View {
    let env: AppEnvironment
    var body: some View {
        NavigationStack {
            BudgetView(transactionService: env.transactionService, budgetProvider: env.budgetProvider)
        }
        .environment(env)
    }
}

#Preview("Loaded") { BudgetPreviewHost(env: .preview()) }
#Preview("Empty") { BudgetPreviewHost(env: .preview(behavior: .empty)) }
#Preview("Failing") { BudgetPreviewHost(env: .preview(behavior: .failing)) }
#Preview("Slow") { BudgetPreviewHost(env: .preview(behavior: .slow)) }
#Preview("Accessibility XXXL") {
    BudgetPreviewHost(env: .preview()).dynamicTypeSize(.accessibility3)
}
#endif

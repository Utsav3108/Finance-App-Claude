import SwiftUI

struct BudgetCategoryRow: View {
    enum Style { case compact, card }

    let spending: CategorySpending
    var style: Style = .card
    var currencyCode: String = "USD"

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var tint: Color {
        spending.isOverBudget ? AppColor.expense : spending.category.tint
    }

    var body: some View {
        Group {
            switch style {
            case .compact: compact
            case .card: card
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    // MARK: Compact (dashboard top categories)

    private var compact: some View {
        HStack(spacing: AppSpacing.sm) {
            CategoryIcon(category: spending.category, size: .small)
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(spending.category.displayName)
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                if let progress = spending.progress {
                    ProgressBar(fraction: progress, tint: tint, height: .compact)
                        .frame(maxWidth: 100)
                }
            }
            Spacer(minLength: AppSpacing.xs)
            Text(amountCaption)
                .font(AppFont.caption)
                .monospacedDigit()
                .foregroundStyle(spending.isOverBudget ? AppColor.expense : AppColor.textTertiaryAccessible)
        }
        .frame(minHeight: AppSize.minTapTarget)
    }

    // MARK: Card (budget screen)

    private var card: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                CategoryIcon(category: spending.category, size: .regular)
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(spending.category.displayName)
                        .font(AppFont.titleScreen)
                        .foregroundStyle(AppColor.textPrimary)
                    Text(spending.transactionCount == 1 ? "1 transaction" : "\(spending.transactionCount) transactions")
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textTertiaryAccessible)
                }
                Spacer(minLength: 0)
            }
            if let remaining = spending.remaining {
                HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xs) {
                    Text(MoneyFormat.magnitude(remaining, currencyCode: currencyCode))
                        .font(AppFont.amountCard)
                        .monospacedDigit()
                        .foregroundStyle(spending.isOverBudget ? AppColor.expense : AppColor.textPrimary)
                    Text(spending.isOverBudget ? "over" : "left")
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textTertiaryAccessible)
                    if spending.isOverBudget {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(AppColor.expense)
                            .accessibilityHidden(true)
                    }
                }
                if let progress = spending.progress {
                    ProgressBar(fraction: progress, tint: tint, height: .medium)
                }
                Text(amountCaption)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textTertiaryAccessible)
            } else {
                Text(MoneyFormat.magnitude(spending.spent, currencyCode: currencyCode))
                    .font(AppFont.amountCard)
                    .monospacedDigit()
                    .foregroundStyle(AppColor.textPrimary)
                Text("spent, no budget set")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textTertiaryAccessible)
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColor.fillSecondary, in: RoundedRectangle(cornerRadius: AppRadius.card))
    }

    private var amountCaption: String {
        let spent = MoneyFormat.compact(spending.spent, currencyCode: currencyCode)
        guard let budget = spending.budget else { return "\(spent) spent" }
        return "\(spent) / \(MoneyFormat.compact(budget, currencyCode: currencyCode))"
    }

    private var accessibilityText: String {
        let name = spending.category.displayName
        let spent = MoneyFormat.magnitude(spending.spent, currencyCode: currencyCode)
        guard let budget = spending.budget, let remaining = spending.remaining else {
            return "\(name), \(spent) spent, no budget"
        }
        let total = MoneyFormat.magnitude(budget, currencyCode: currencyCode)
        let percent = Int(((spending.progress ?? 0) * 100).rounded())
        if remaining < 0 {
            return "\(name), \(spent) of \(total) spent, \(percent) percent, over budget by \(MoneyFormat.magnitude(remaining, currencyCode: currencyCode))"
        }
        return "\(name), \(spent) of \(total) spent, \(percent) percent, \(MoneyFormat.magnitude(remaining, currencyCode: currencyCode)) left"
    }
}

#Preview("BudgetCategoryRow") {
    ScrollView {
        VStack(spacing: AppSpacing.md) {
            BudgetCategoryRow(spending: CategorySpending(category: .dining, spent: 180, budget: 250, transactionCount: 4), style: .compact)
            BudgetCategoryRow(spending: CategorySpending(category: .dining, spent: 180, budget: 250, transactionCount: 4))
            BudgetCategoryRow(spending: CategorySpending(category: .shopping, spent: 340, budget: 300, transactionCount: 2))
            BudgetCategoryRow(spending: CategorySpending(category: .other, spent: 37, budget: nil, transactionCount: 1))
        }
        .padding(AppSpacing.lg)
    }
    .background(AppColor.surface)
}

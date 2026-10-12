import SwiftUI

/// Dashboard hero: month pill, adjust pill, amount left, bar and "spent / total" caption.
struct BalanceCard: View {
    let title: String
    let amount: Decimal
    let spent: Decimal
    let total: Decimal
    let monthLabel: String
    var currencyCode: String = "USD"
    var onAdjust: (() -> Void)?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return NSDecimalNumber(decimal: spent / total).doubleValue
    }

    private var isOver: Bool { total > 0 && spent > total }

    private var summaryText: String {
        "\(MoneyFormat.compact(spent, currencyCode: currencyCode)) / \(MoneyFormat.compact(total, currencyCode: currencyCode)) spent"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text(monthLabel)
                    .font(AppFont.chipLabel)
                    .foregroundStyle(AppColor.textPrimary)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(AppColor.fillSecondary, in: Capsule())
                Spacer()
                if let onAdjust {
                    PillButton(systemImage: "slider.horizontal.3", accessibilityLabel: "Adjust budget", action: onAdjust)
                }
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xs) { amountText; titleText }
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) { amountText; titleText }
                }
                ProgressBar(fraction: fraction, tint: isOver ? AppColor.expense : AppColor.accentWarning, height: .large)
                HStack(spacing: AppSpacing.xxs) {
                    if isOver {
                        Image(systemName: "exclamationmark.triangle.fill").accessibilityHidden(true)
                    }
                    Text(isOver ? "\(summaryText), over budget" : summaryText)
                }
                .font(AppFont.caption)
                .foregroundStyle(isOver ? AppColor.expense : AppColor.textTertiaryAccessible)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(title), \(MoneyFormat.magnitude(amount, currencyCode: currencyCode)). \(summaryText)\(isOver ? ", over budget" : "")")
        }
        .padding(AppSpacing.md)
        .background(AppColor.fillPrimary, in: RoundedRectangle(cornerRadius: AppRadius.card))
        .overlay(RoundedRectangle(cornerRadius: AppRadius.card).strokeBorder(AppColor.borderPrimary, lineWidth: 1))
    }

    private var amountText: some View {
        Text(MoneyFormat.signed(amount, currencyCode: currencyCode))
            .font(AppFont.amountHero)
            .monospacedDigit()
            .foregroundStyle(amount < 0 ? AppColor.expense : AppColor.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }

    private var titleText: some View {
        Text(title).font(AppFont.caption).foregroundStyle(AppColor.textTertiaryAccessible)
    }
}

#Preview("BalanceCard") {
    VStack(spacing: AppSpacing.md) {
        BalanceCard(title: "Left", amount: 2215.90, spent: 1284.10, total: 3500, monthLabel: "October") {}
        BalanceCard(title: "Left", amount: -120, spent: 3620, total: 3500, monthLabel: "October")
    }
    .padding(AppSpacing.lg)
    .background(AppColor.surface)
}

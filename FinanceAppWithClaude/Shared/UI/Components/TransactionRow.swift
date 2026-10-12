import SwiftUI

/// Display data for `TransactionRow`; built by view models (or `init(_: Transaction)`).
struct TransactionRowModel: Hashable, Identifiable {
    var id: String
    var title: String
    var caption: String
    var amount: Decimal
    var currencyCode: String
    var date: Date
    var category: TransactionCategory
    var isReviewed: Bool

    init(id: String, title: String, caption: String, amount: Decimal, currencyCode: String = "USD",
         date: Date, category: TransactionCategory, isReviewed: Bool) {
        self.id = id
        self.title = title
        self.caption = caption
        self.amount = amount
        self.currencyCode = currencyCode
        self.date = date
        self.category = category
        self.isReviewed = isReviewed
    }

    init(_ t: Transaction) {
        self.init(id: t.id, title: t.title, caption: t.category.displayName, amount: t.amount,
                  currencyCode: t.currencyCode, date: t.date, category: t.category, isReviewed: t.isReviewed)
    }

    static let placeholder = TransactionRowModel(
        id: "placeholder", title: "Placeholder merchant", caption: "Category", amount: -12.34,
        date: Date(timeIntervalSince1970: 0), category: .other, isReviewed: true)

    var accessibilityLabel: String {
        "\(title), \(caption), \(MoneyFormat.spoken(amount, currencyCode: currencyCode)), "
            + "\(MoneyFormat.shortDate(date)), \(isReviewed ? "reviewed" : "not reviewed")"
    }
}

struct TransactionRow: View {
    let model: TransactionRowModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: AppSpacing.xs))
            : AnyLayout(HStackLayout(alignment: .center, spacing: AppSpacing.sm))
        layout {
            CategoryIcon(category: model.category, size: .regular)
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                HStack(spacing: AppSpacing.xs) {
                    Text(model.title)
                        .font(AppFont.rowTitle)
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                    if !model.isReviewed {
                        ReviewedStatusBadge(isReviewed: false, style: .compact)
                    }
                }
                Text(model.caption)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textTertiaryAccessible)
            }
            if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: AppSpacing.xs) }
            VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing, spacing: AppSpacing.xxs) {
                AmountText(amount: model.amount, currencyCode: model.currencyCode, style: .row)
                Text(MoneyFormat.shortDate(model.date))
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textTertiaryAccessible)
            }
        }
        .frame(minHeight: AppSize.minTapTarget)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(model.accessibilityLabel)
    }
}

#Preview("TransactionRow") {
    VStack(spacing: AppSpacing.xl) {
        TransactionRow(model: TransactionRowModel(PreviewData.transactions[0]))
        TransactionRow(model: TransactionRowModel(PreviewData.transactions[1]))
        TransactionRow(model: TransactionRowModel(id: "x", title: "A very long merchant name that should truncate on one line",
                                                  caption: "Dining", amount: -123.45, date: .now, category: .dining, isReviewed: true))
        TransactionRow(model: .placeholder).redacted(reason: .placeholder)
    }
    .padding(AppSpacing.lg)
    .background(AppColor.surface)
}

#Preview("TransactionRow AX5", traits: .fixedLayout(width: 393, height: 600)) {
    TransactionRow(model: TransactionRowModel(PreviewData.transactions[0]))
        .padding(AppSpacing.lg)
        .background(AppColor.surface)
        .dynamicTypeSize(.accessibility5)
}

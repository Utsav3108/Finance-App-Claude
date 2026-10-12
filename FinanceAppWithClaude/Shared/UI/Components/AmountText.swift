import SwiftUI

struct AmountText: View {
    enum Style { case hero, card, row, detail }

    let amount: Decimal
    let currencyCode: String
    var style: Style = .row

    var body: some View {
        Text(MoneyFormat.signed(amount, currencyCode: currencyCode))
            .font(font)
            .monospacedDigit()
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(style == .hero ? 0.6 : 1)
            .accessibilityLabel(MoneyFormat.spoken(amount, currencyCode: currencyCode))
    }

    private var font: Font {
        switch style {
        case .hero, .detail: AppFont.amountHero
        case .card: AppFont.amountCard
        case .row: AppFont.rowTitle
        }
    }

    private var color: Color {
        if amount < 0 { AppColor.expense } else if amount > 0 { AppColor.income } else { AppColor.textPrimary }
    }
}

#Preview("AmountText") {
    VStack(alignment: .leading, spacing: 12) {
        AmountText(amount: -54.20, currencyCode: "USD", style: .hero)
        AmountText(amount: 3000, currencyCode: "USD", style: .card)
        AmountText(amount: -7.99, currencyCode: "USD")
        AmountText(amount: 0, currencyCode: "USD")
    }
    .padding()
    .background(AppColor.surface)
}

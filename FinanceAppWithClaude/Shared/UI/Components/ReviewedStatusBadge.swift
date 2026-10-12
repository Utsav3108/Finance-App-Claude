import SwiftUI

struct ReviewedStatusBadge: View {
    enum Style { case compact, full }

    let isReviewed: Bool
    var style: Style = .full

    var body: some View {
        switch style {
        case .compact:
            Image(systemName: icon)
                .font(AppFont.caption)
                .foregroundStyle(tint)
                // Folded into the owning row's accessibility label.
                .accessibilityHidden(true)
        case .full:
            Label(text, systemImage: icon)
                .font(AppFont.chipLabel)
                .foregroundStyle(isReviewed ? AppColor.income : AppColor.textSecondary)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background(AppColor.fillSecondary, in: Capsule())
                .accessibilityElement(children: .combine)
        }
    }

    private var icon: String { isReviewed ? "checkmark.circle.fill" : "circle.dashed" }
    private var text: String { isReviewed ? "Reviewed" : "Not reviewed" }
    private var tint: Color { isReviewed ? AppColor.accentBrand : AppColor.textTertiaryAccessible }
}

#Preview("ReviewedStatusBadge") {
    VStack(alignment: .leading, spacing: 12) {
        ReviewedStatusBadge(isReviewed: true)
        ReviewedStatusBadge(isReviewed: false)
        ReviewedStatusBadge(isReviewed: false, style: .compact)
    }
    .padding()
    .background(AppColor.surface)
}

import SwiftUI

struct CategoryBadge: View {
    enum Style { case icon, iconAndLabel }

    let category: TransactionCategory
    var style: Style = .iconAndLabel
    var isSelected = false

    @ScaledMetric(relativeTo: .footnote) private var iconSize: CGFloat = 16

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: category.systemImage)
                .font(.system(size: iconSize))
                .foregroundStyle(category.tint)
                .accessibilityHidden(true)
            if style == .iconAndLabel {
                Text(category.displayName)
                    .font(AppFont.chipLabel)
                    .foregroundStyle(AppColor.textPrimary)
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .frame(minHeight: AppSize.minTapTarget - AppSpacing.xs)
        .background(isSelected ? AppColor.accentBrand.opacity(0.12) : AppColor.fillSecondary, in: Capsule())
        .overlay(Capsule().strokeBorder(isSelected ? AppColor.accentBrand : .clear, lineWidth: 1.5))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(category.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview("CategoryBadge") {
    VStack(alignment: .leading, spacing: 12) {
        CategoryBadge(category: .dining)
        CategoryBadge(category: .groceries, isSelected: true)
        CategoryBadge(category: .transport, style: .icon)
    }
    .padding()
    .background(AppColor.surface)
}

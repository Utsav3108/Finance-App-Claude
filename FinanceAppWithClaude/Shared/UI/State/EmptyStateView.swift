import SwiftUI

struct EmptyStateView: View {
    let config: EmptyStateConfig

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: config.systemImage)
                .font(.system(size: 40))
                .foregroundStyle(AppColor.iconSecondary)
                .accessibilityHidden(true)
            VStack(spacing: AppSpacing.xs) {
                Text(config.title)
                    .font(AppFont.titleScreen)
                    .foregroundStyle(AppColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text(config.message)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.textTertiaryAccessible)
            }
            .multilineTextAlignment(.center)
            .accessibilityElement(children: .combine)
            if let title = config.actionTitle, let action = config.action {
                PrimaryButton(title, action: action)
                    .frame(maxWidth: 280)
            }
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity)
    }
}

#Preview("EmptyStateView") {
    EmptyStateView(config: EmptyStateConfig(
        title: "No transactions", message: "Add your first transaction to see it here.",
        actionTitle: "Add transaction") {})
        .background(AppColor.surface)
}

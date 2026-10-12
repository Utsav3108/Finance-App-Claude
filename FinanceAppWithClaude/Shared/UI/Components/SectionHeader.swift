import SwiftUI

struct SectionHeader: View {
    let title: String
    var subtitle: String?
    var actionTitle: String?
    var actionAccessibilityLabel: String?
    var action: (() -> Void)?

    init(title: String, subtitle: String? = nil, actionTitle: String? = nil,
         actionAccessibilityLabel: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.actionAccessibilityLabel = actionAccessibilityLabel
        self.action = action
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(title)
                    .font(AppFont.rowTitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                if let subtitle {
                    Text(subtitle)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.textTertiaryAccessible)
                }
            }
            Spacer(minLength: 0)
            if let actionTitle, let action {
                PillButton(title: actionTitle, accessibilityLabel: actionAccessibilityLabel, action: action)
            }
        }
    }
}

#Preview("SectionHeader") {
    VStack(spacing: 24) {
        SectionHeader(title: "Recent transactions", subtitle: "Last 5", actionTitle: "See all",
                      actionAccessibilityLabel: "See all recent transactions") {}
        SectionHeader(title: "Expense categories")
    }
    .padding(AppSpacing.lg)
    .background(AppColor.surface)
}
